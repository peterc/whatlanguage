#        NAME: BloominSimple
#      AUTHOR: Peter Cooper
#     LICENSE: MIT ( http://www.opensource.org/licenses/mit-license.php )
#   COPYRIGHT: (c) 2007 Peter Cooper
# DESCRIPTION: Very basic, pure Ruby Bloom filter. Uses my BitField, pure Ruby
#              bit field library (http://snippets.dzone.com/posts/show/4234).
#              Supports custom hashing (default is 3).
#
#              Create a Bloom filter that uses default hashing with 1Mbit wide bitfield
#                bf = BloominSimple.new(1_000_000)
#              
#              Add items to it
#                File.open('/usr/share/dict/words').each { |a| bf.add(a) }
#
#              Check for existence of items in the filter
#                bf.includes?("people")     # => true
#                bf.includes?("kwyjibo")    # => false
#
#              Add better hashing (c'est easy!)
#                require 'digest/sha1'
#                b = BloominSimple.new(1_000_000) do |item|
#                  Digest::SHA1.digest(item.downcase.strip).unpack("VVVV")
#                end
#
#              More
#                %w{wonderful ball stereo jester flag shshshshsh nooooooo newyorkcity}.each do |a|
#                  puts "#{sprintf("%15s", a)}: #{b.includes?(a)}"
#                end
#
#                 #  =>   wonderful: true
#                 #  =>        ball: true
#                 #  =>      stereo: true
#                 #  =>      jester: true
#                 #  =>        flag: true
#                 #  =>  shshshshsh: false
#                 #  =>    nooooooo: false
#                 #  => newyorkcity: false

require 'whatlanguage/bitfield'

class BloominSimple
  attr_accessor :bitfield, :hasher
  
  def initialize(bitsize, &block)
    @bitfield = BitField.new(bitsize)
    @size = bitsize
    @hasher = block || lambda do |word|
      word = word.downcase.strip
      [h1 = word.sum, h2 = word.hash, h2 + h1 ** 3]
    end
  end
  
  # Add item to the filter
  def add(item)
    @hasher[item].each { |hi| @bitfield[hi % @size] = 1 }
  end
  
  # Find out if the filter possibly contains the supplied item
  def includes?(item)
    @hasher[item].each { |hi| return false unless @bitfield[hi % @size] == 1 } and true
  end
  
  # Allows comparison between two filters. Returns number of same bits.
  def &(other)
    raise "Wrong sizes" if self.bitfield.size != other.bitfield.size
    same = 0
    #self.bitfield.size.times do |pos|
    #  same += 1 if self.bitfield[pos] & other.bitfield[pos] == 1
    #end
    self.bitfield.total_set.to_s + "--" + other.bitfield.total_set.to_s
  end

  # Dumps the bitfield for a bloom filter for storage
  def dump
    [@size, *@bitfield.field].pack("I*")
    #Marshal.dump([@size, @bitfield])
  end
  
  # Creates a new bloom filter object from a stored dump (hasher has to be resent though for additions)
  def self.from_dump(data, &block)
    data = data.unpack("I*")
    #data = Marshal.load(data)
    temp = new(data[0], &block)
    temp.bitfield.field = data[1..-1]
    temp
  end
end

