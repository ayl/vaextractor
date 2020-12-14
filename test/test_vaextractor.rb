require 'minitest/autorun'
require 'vaextractor'

class VAExtractorTest < Minitest::Test
	def test_example1
		a = VAExtractor.new
		assert_equal({:RE=>["20", "20", "-", "1"], :LE=>["20", "20", "+", "1"], :RElogmar=>0.0194, :LElogmar=>-0.025} , a.extract(IO.read("examples/example1.txt")))
	end
	def test_example2
		a = VAExtractor.new
		assert_equal({:RE=>["20", "20", nil, nil], :LE=>["20", "30", "+", "1"], :RElogmar=>-0.0, :LElogmar=>0.1603} , a.extract(IO.read("examples/example2.txt")))
	end
	def test_example3
		a = VAExtractor.new
		assert_equal({:RE=>["20", "20", "-", "1"], :LE=>["20", "30", "+", "2"], :RElogmar=>0.0194, :LElogmar=>0.1444} , a.extract(IO.read("examples/example3.txt")))
	end
	def test_example4
		a = VAExtractor.new
		assert_equal({:RE=>["20", "30", nil, nil], :LE=>[nil, nil, nil, nil], :RElogmar=>0.1761, :LElogmar=>nil} , a.extract(IO.read("examples/example4.txt")))
	end

	def test_find_laterality_and
		a = VAExtractor.new
		tokens = [['OS', 15], ['AND', 18]]
		_, answers = a.findlaterality(20, tokens, '')
		assert_equal({5 => [['OS', 5]]}, answers)
	end

	def test_find_laterality_amp
		a = VAExtractor.new
		tokens = [['OS', 15], ['!', 18]]
		_, answers = a.findlaterality(20, tokens, '')
		assert_equal({10 => [['OS', 5]]}, answers)
	end

end
