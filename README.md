# visualAcuityExtractor

This project is to perform Natural Language Processing (NLP) using a rule-based
approach for the purposes of extracting Snellen visual acuities from
ophthalmology clinical text notes.

The code works with numerous different visual acuity documentation styles and
will output the best corrected visual acuity for each eye. In addition, it will
also convert the visual acuities into logMAR and output into a tab delimited
fashion allowing for easy of use into statistical programs for analysis.  The
output for several files is meant to be concatenated together.

## Requirements

* Ruby
* textoken gem

## Installation

```ruby
gem install vaextractor
```

## Usage

```ruby
require 'vaextractor'
a = VAExtractor.new
a.extract(IO.read("examples/example1.txt"))
 => {:RE=>["20", "20", "-", "1"], :LE=>["20", "20", "+", "1"], :RElogmar=>0.0194, :LElogmar=>-0.025} 
```

## Output format

The extract function outputs a ruby hash with the following values

* :RE - visual acuity array for right eye
* :LE - visual acuity array for left eye
* :RElogmar - logMAR visual acuity for right eye
* :LElogmar - logMAR visual acuity for left eye

Visual acuity array is enumerated as:

1. Numerator eg. 20, HM, CF
2. Denominator eg. 30
3. Adjustment eg. +
4. Letters eg. 2

## Examples

Example text files are provided in examples/ to give the user an idea of the
different formats the extractor is capable of extracting. 


## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Copyright

Copyright 2016, Aaron Y. Lee MD MSCI. University of Washington, Seattle WA
