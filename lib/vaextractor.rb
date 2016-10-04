#!/usr/bin/env ruby
# Copyright 2016 Aaron Y. Lee MD MSCI 
# University of Washington, Seattle WA
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
#
require 'textoken'

class VAExtractor
	@@varegex = /(\s|^|~|:)(20|3E|E)\/\s*(\d+)\s*([+|-])*\s*(\d)*|(HM|CF|LP|NLP)(\W+(@|at|x)*\s*((\d+)(\s*'|\s*"|\s*in|\s*ft|\s*feet)*|face)*|$)/
	@@snellenlevels = [10,15,20,25,30,40,50,60,70,80,100,125,150,200,250,300,400,600,800]
	@@validtokens = {"OD" => "OD", "RE" => "OD", "RIGHT" => "OD", "R" => "OD", 
			"L" => "OS", "OS" => "OS", "LE" => "OS", "LEFT" => "OS", 
			"BOTH" => "OU", "BE" => "OU", "OU" => "OU", "BILATERAL" => "OU"}
	def initialize
		@usedsnellen = {}
		@@snellenlevels.each do |k|
			@usedsnellen[k] = -Math.log(20.0 / k) / Math.log(10.0)
		end
	end

	def aligntokens(s)
		arr = Textoken(s).tokens
		ret = []
		lasti = 0
		arr.each do |w|
			subs = s[lasti, s.size]
			i = subs.index(w)
			ret.push [w, lasti + i]
			lasti += i
		end
		return ret
	end

	def runentirefreq(rawtext)
		tokens = aligntokens(rawtext)
		scores = Hash.new(0)
		tokens.each do |w, i|
			w = w.upcase
			if @@validtokens.has_key?(w) and @@validtokens[w] != "OU"
				scores[@@validtokens[w]] += 1
			end
		end
		return nil if scores.keys.count == 0
		#p scores
		return scores.sort_by {|k,v| v}.last.first
	end


	def logmar(va)
		if va[0] == "20"
			manual = @usedsnellen[va[1].to_i]
			if va[2] == "+"
				va[3] = "1" if va[3] == nil
				denom = @@snellenlevels.index(va[1].to_i)
				denom -= 1
				denom = @usedsnellen[@@snellenlevels[denom]]
				manual = 1.0 * va[3].to_i * (denom - manual) / 5.0 + manual
			elsif va[2] == "-"
				va[3] = "1" if va[3] == nil
				denom = @@snellenlevels.index(va[1].to_i)
				denom += 1
				denom = @usedsnellen[@@snellenlevels[denom]]
				manual = 1.0 * va[3].to_i * (denom - manual) / 5.0 + manual
			end
			return manual, va[0...4]
		elsif va[0] == "3E" or va[0] == "3" or va[0] == "E"
			denom = va[1].to_i
			return -Math.log(3.0 / denom) / Math.log(10.0), va[0...4]
		elsif va[4] == "CF"
			return 2.0, [va[4],va[8],va[9],nil]
		elsif va[4] == "HM"
			return 2.4, [va[4],va[8],va[9],nil]
		elsif va[4] == "LP"
			return 2.7, [va[4],va[8],va[9],nil]
		elsif va[4] == "NLP"
			return 3.0, [va[4],va[8],va[9],nil]
		end
		return nil, nil
	end

	def searchpriorlines(lines)
		lines.each do |l|
			return nil if l.strip == ""
			arr = Textoken(l).tokens
			arr.each do |w|
				if @@validtokens.has_key?(w.upcase)
					next if @@validtokens[w.upcase] == "OU"
					return @@validtokens[w.upcase]
				end
			end
		end
		return nil
	end


	def findlaterality(pos, tokens, linestr)
		walls = {"." => 10, "!" => 10, "?" => 10, "," => 5, "and" => 5}
		answers = {}
		debug = ""
		revtoken = {}
		tokens.each do |w, i|
			revtoken[i] = w
		end
		tokens.each do |w, i|
			w = w.upcase
			if @@validtokens.has_key?(w)
				score = 0
				l = i
				r = pos
				l = pos if i > pos
				r = i if i > pos
				(l...r).each do |j|
					next if not revtoken.has_key?(j)
					score += walls[revtoken[j]] if walls.has_key?(revtoken[j])
				end
				if not answers.has_key?(score)
					answers[score] = []
				end
				answers[score].push [@@validtokens[w], (i-pos).abs]
			end
		end
		return nil if answers.keys.count == 0

		bestscore = answers.sort_by {|k, v| k}.first.last
		sorted = bestscore.sort_by {|r| r[1]}
		return sorted.first[0], answers
	end


	def extract(rawtext)
		lines = rawtext.split("\n")
		debug = false

		rfound = false
		lfound = false
		found = false
		vas = {"OD" => [], "OS" => []}
		alreadychecked = {}
		debugtxt = ""
		for i in (0...lines.count)
			next if lines[i].strip=~ /^IOP/ or lines[i].strip =~ /^Ta\s/ or lines[i].strip =~ /^Tp/i
			next if alreadychecked.has_key?(i)
			arr = lines[i].scan(@@varegex)
			lines[i].enum_for(:scan, @@varegex).each do |val|
				#puts "============================================="
				debugtxt += "NEW VA DETECTED\n"
				debugtxt += "#{lines[i-1]}\n"
				debugtxt += "#{lines[i]}\n"
				debugtxt += "#{lines[i+1]}\n"
				debugtxt += "#{val}\n"
				val.shift
				next if val[3] != nil  and val[3].to_i >= 5
				pos = Regexp.last_match.begin(0)
				tokens = aligntokens(lines[i])
				lat,debughash = findlaterality(pos, tokens, lines[i])
				debugtxt += "#{pos}\n"
				debugtxt += "#{tokens}\n"
				debugtxt += "#{debughash}\n"
				#p lat
				if lat == "OU"
					vas["OD"].push [val, i, 5]
					vas["OS"].push [val, i, 5]
				elsif lat != nil
					vas[lat].push  [val, i, 5]
				elsif lat == nil and vas["OD"].count == 0 and vas["OS"].count == 0
					lat = searchpriorlines(lines[i-3..i-1].reverse)
					if lat == nil and vas["OD"].count == 0 and vas["OS"].count == 0
						# most likely the VAs are either two in one line OD/OS or on two consecutive lines
						found = false
						arr2 = lines[i+1].scan(@@varegex)
						if arr2.count > 0 and arr.count > 0
							arr.each do |row|
								row.shift
								next if row[0] != nil  and row[3].to_i >= 5
								vas["OD"].push [row, i, 0]
							end
							arr2.each do |row|
								row.shift
								next if row[0] != nil  and row[3].to_i >= 5
								vas["OS"].push [row, i+1, 0]
							end
							alreadychecked[i+1] = 1
							found = true
						elsif arr.count == 2
							arr[0].shift
							arr[1].shift
							next if arr[0] != nil  and arr[0][3].to_i >= 5
							next if arr[1] != nil  and arr[1][3].to_i >= 5
							vas["OD"].push [arr[0], i, 0]
							vas["OS"].push [arr[1], i, 0]
							found = true
						end
						if not found 
							# worst case scenario, count up all the occurences of r/l and then take highest occuring freq
							lat = runentirefreq(rawtext)
							if lat == nil
								#puts "ERROR: Laterality not found for #{val}"
								raise ErrorLateralityNotFound
							else
								vas[lat].push [val, i, 0]
							end
						end
					else
						vas[lat].push  [val, i, 3]
					end
					#exit
				end
			end
		end

		if vas["OD"].count == 0 and vas["OS"].count == 0
			#puts "ERROR: No valid visual acuities found"
			return  {:RE => nil, :LE => nil, :RElogmar => nil, :LElogmar => nil}
		else
			bcva = {"OD" => nil, "OS" => nil}
			puts "=================NEW PT" if debug
			puts rawtext if debug
			puts "===DEBUG" if debug
			puts debugtxt if debug
			puts "===OD" if debug

			vas["OD"].each do |varr,line,priority|
				puts "new va" if debug
				p varr if debug
				p lines[line] if debug
				p priority if debug
				lva = logmar(varr)
				p lva if debug
				if bcva["OD"] == nil or (bcva["OD"][0] <= priority  and lva[0] < bcva["OD"][1])
					bcva["OD"] = [priority, lva[0].round(4), lva[1]]
				end
			end
			puts "===OS" if debug
			vas["OS"].each do |varr,line,priority|
				puts "new va" if debug
				p varr if debug
				p lines[line] if debug
				p priority if debug
				lva = logmar(varr)
				p lva if debug
				if bcva["OS"] == nil or (bcva["OS"][0] <= priority  and lva[0] < bcva["OS"][1])
					bcva["OS"] = [priority, lva[0].round(4), lva[1]]
				end
			end
			bcva["OD"] = [nil, nil, [nil,nil,nil,nil]] if bcva["OD"] == nil
			bcva["OS"] = [nil, nil, [nil,nil,nil,nil]] if bcva["OS"] == nil
			return  {:RE => bcva["OD"][2], :LE => bcva["OS"][2], :RElogmar => bcva["OD"][1], :LElogmar => bcva["OS"][1]}
		end
	end
end
