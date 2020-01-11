class Array
  def strict_include?(obj)
    self.each { |item| return true if item.equal?(obj) }
    return false
  end
end

class Node
  include Comparable
  attr_accessor :value
  attr_reader :left, :right

  def initialize(value=nil, leaf=false)
    @value = value
    if leaf
      @left = Node.new(leaf=true)
      @right = Node.new(leaf=true)
    end
  end

  def left=(obj)
    return @left = obj if obj.class == Node
    raise "Cannot store #{obj.class} as a child of Node"
  end

  def right=(obj)
    return @right = obj if obj.class == Node
    raise "Cannot store #{obj.class} as a child of Node"
  end

  def <=>(other)
    return @value <=> other.value if other.class == Node
    raise "Cannot compare Node with #{other.class}"
  end

  def leaf?
    @left.nil? && @right.nil?
  end

  def to_s
    "#{super.to_s}\n" +
    "  Value = #{value}\n" +
    "  Left child = #{@left.nil? ? "none" : (@left.leaf? ? "<leaf>" : @left.value)}\n" +
    "  Right child = #{@right.nil? ? "none" : (@right.leaf? ? "<leaf>" : @right.value)}"
  end

  def to_s_recursive(depth=0)
    return "" if self.leaf?
    " " * depth + "#{@value}\n" + @left.to_s_recursive(depth + 1) + @right.to_s_recursive(depth + 1)
  end
end

class Tree
  attr_accessor :root

  def initialize(data=nil)
    @root = data.nil? ? nil : build_tree(data)
  end

  def balanced?
    (depth(@root.left) - depth(@root.right)).abs <= 1
  end

  def delete(value, root=@root)
    if @root.value == value
      @root = find_replacement(@root)
    else
      next_node = value < root.value ? root.left : root.right

      return nil if next_node.leaf?

      if next_node.value == value
        new_node = find_replacement(next_node)
        if next_node == root.left
          root.left = new_node
        else
          root.right = new_node
        end
      else
        delete(value, next_node)
      end
    end

    return nil
  end

  def depth(node)
    return -1 if node.nil?
    return 0 if node.leaf?
    left_depth = depth(node.left) + 1
    right_depth = depth(node.right) + 1
    return left_depth > right_depth ? left_depth : right_depth
  end

  def find(value, root=@root)
    return root if root.value == value
    return nil if root.leaf?
    return find(value, (value < root.value) ? root.left : root.right)
  end

  def insert(value, root=@root)
    if root.leaf?
      root.value = value
      root.left = Node.new(leaf=true)
      root.right = Node.new(leaf=true)
    else
      insert(value, (value < root.value) ? root.left : root.right)
    end
    return root
  end

  def inorder
    discovered = []
    visited = []

    discovered.push @root
    until discovered.empty? do
      current = discovered.last
      if visited.strict_include?(current.left) || current.left.leaf?
        yield current if block_given?
        visited.push(discovered.pop)
        discovered.push(current.right) unless current.right.leaf?
      else
        discovered.push(current.left)
      end
    end

    return visited.reduce([]) { |values, node| values.push node.value }
  end

  def postorder
    discovered = []
    visited = []

    discovered.push @root
    until discovered.empty? do
      current = discovered.last
      if !(visited.strict_include?(current.left) || current.left.leaf?)
        discovered.push(current.left)
      elsif !(visited.strict_include?(current.right) || current.right.leaf?)
        discovered.push(current.right)
      else
        yield current if block_given?
        visited.push(discovered.pop)
      end
    end

    return visited.reduce([]) { |values, node| values.push node.value }
  end

  def preorder
    discovered = []
    visited = []

    discovered.push @root
    until discovered.empty? do
      current = discovered.last
      if visited.strict_include? current
        discovered.pop
        discovered.push(current.right) unless current.right.leaf?
      else
        yield current if block_given?
        visited.push current
        discovered.push(current.left) unless current.left.leaf?
      end
    end

    return visited.reduce([]) { |values, node| values.push node.value }
  end

  def level_order
    discovered = []
    visited = []

    discovered.push @root
    until discovered.empty? do
      current = discovered.shift

      yield current if block_given?
      visited.push current

      discovered.push(current.left) unless current.left.leaf?
      discovered.push(current.right) unless current.right.leaf?
    end

    return visited.reduce([]) { |values, node| values.push node.value }
  end

  def rebalance!
    @root = build_tree(self.inorder)
  end

  def to_s
    @root.to_s_recursive
  end

  private
  def build_tree(data)
    raise("Invalid data type: Tree.new expects Array as input") \
      unless data.instance_of?(Array)
    return Node.new(leaf=true) if data.length == 0
    data = data.uniq.sort
    middle = data.length / 2
    root = Node.new(data[middle])
    root.left = build_tree(data[0...middle])
    root.right = build_tree(data[(middle + 1)..-1])
    return root
  end

  def find_replacement(node)
    return nil if node.nil?
    if node.leaf? || (node.left.leaf? && node.right.leaf?)
      return Node.new(leaf=true)
    elsif node.left.leaf?
      return node.right
    elsif node.right.leaf?
      return node.left
    else
      return depth(node.left) >= depth(node.right) ? node.left : node.right
    end
  end
end

# Issues: delete is bjorked; if node to delete has two children, one will be lost.
# Also applies to the iterative version.

a = Array.new(15) { rand(1..100) }
tree = Tree.new(a)
puts tree
puts "Level order:"
p tree.level_order
puts "Inorder:"
p tree.inorder
puts "Preorder:"
p tree.preorder
puts "Postorder:"
p tree.postorder
puts tree.find(1)
tree.insert(500)
puts tree.find(500)
tree.delete(500)
puts tree.find(500)
puts tree.balanced?
tree.insert(121)
tree.insert(144)
tree.insert(169)
puts tree
puts tree.balanced?
tree.rebalance!
puts tree
puts tree.balanced?
tree.delete(tree.root.value)
puts tree
