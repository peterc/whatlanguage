#        NAME: BitField
#      AUTHOR: Peter Cooper
#     LICENSE: MIT ( http://www.opensource.org/licenses/mit-license.php )
#   COPYRIGHT: (c) 2007 Peter Cooper (http://www.petercooper.co.uk/)
#     VERSION: v4
#     HISTORY: v4 (better support for loading and dumping fields)
#              v3 (supports dynamic bitwidths for array elements.. now doing 32 bit widths default)
#              v2 (now uses 1 << y, rather than 2 ** y .. it's 21.8 times faster!)
#              v1 (first release)
#
# DESCRIPTION: Basic, pure Ruby bit field. Pretty fast (for what it is) and memory efficient.
#              I've written a pretty intensive test suite for it and it passes great. 
#              Works well for Bloom filters (the reason I wrote it).
#
#              Create a bit field 1000 bits wide
#                bf = BitField.new(1000)
#
#              Setting and reading bits
#                bf[100] = 1
#                bf[100]    .. => 1
#                bf[100] = 0
#
#              More
#                bf.to_s = "10101000101010101"  (example)
#                bf.total_set         .. => 10  (example - 10 bits are set to "1")

class BitField
  attr_reader :size
  attr_accessor :field
  include Enumerable
  
  ELEMENT_WIDTH = 32
  
  def initialize(size)
    @size = size
    @field = Array.new(((size - 1) / ELEMENT_WIDTH) + 1, 0)
  end
  
  # Set a bit (1/0)
  def []=(position, value)
    value == 1 ? @field[position / ELEMENT_WIDTH] |= 1 << (position % ELEMENT_WIDTH) : @field[position / ELEMENT_WIDTH] ^= 1 << (position % ELEMENT_WIDTH)
  end
  
  # Read a bit (1/0)
  def [](position)
    @field[position / ELEMENT_WIDTH] & 1 << (position % ELEMENT_WIDTH) > 0 ? 1 : 0
  end
  
  # Iterate over each bit
  def each(&block)
    @size.times { |position| yield self[position] }
  end
  
  # Returns the field as a string like "0101010100111100," etc.
  def to_s
    inject("") { |a, b| a + b.to_s }
  end
  
  # Returns the total number of bits that are set
  # (The technique used here is about 6 times faster than using each or inject direct on the bitfield)
  def total_set
    @field.inject(0) { |a, byte| a += byte & 1 and byte >>= 1 until byte == 0; a }
  end
end