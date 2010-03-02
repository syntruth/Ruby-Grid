=begin rdoc

Grid Class for Games or whatever else you can think of.
By Randy Carnahan, released to the Public Domain.

* Version 1.0b  - 7/13/2006
* Version 1.0   - 7/19/2006 - Last Lua version
* Version 1.0RB - 9/26/2007 - Ruby Version

Caveats:

  * The Grid object is data agnostic.  It doesn't care what 
    kind of data you store in a cell. This is meant to be, 
    for abstraction's sake. You could even store functions.
  * The class defines -no- display methods. Either sub-class
    the Grid class to add your own, or define functions that
    call the get_*() methods.
  * Grid coordinates are always x,y number pairs. X is the 
    vertical, starting at the top left, and Y is the 
    horizontal, also starting at the top left. Hence, the 
    top-left cell is always 0,0. One cell to the right is
    0,1. One cell down is 1,0.
  * Some Grid constants (OUTSIDE, NOT_VALID, NIL_VALUE) are 
    not numbers, but strings, just in case number data is to 
    be stored in a cell.

Example:

  require "grid"
  g = Grid::create(8, 8, " ")
  c = [[4, 4, "O"], [4, 5, "X"], [5, 4, "X"], [5, 5, "O"]]
  g.populate(c)
  g.traverse(0, 0, Grid::BOTTOM_RIGHT) do |x, y, value|
    puts "#{x}, #{y}: #{value}"
  end
  g.resize(4, 4)
  g.get_cell(3, 3)

=end

module Grid

  # Some constant values. These are set as strings instead of 
  # integer values to prevent clashes of data.
  OUTSIDE   = "OUTSIDE".freeze()
  NOT_VALID = "NOT_VALID".freeze()
  NIL_VALUE = "NIL_VALUE".freeze()

  # Traversal Vector Constants
  TOP_LEFT = 1
  TOP = 2
  TOP_RIGHT = 3
  LEFT = 4
  CENTER = 5
  RIGHT = 6
  BOTTOM_LEFT = 7
  BOTTOM = 8
  BOTTOM_RIGHT = 9

  # GridBase Class Definition
  class GridBase

    # GridBase constructor.
    # +sizex+ and +sizey+::
    #   These set the desired size of the grid, 4 by default.
    # +def_value+::
    #   The default data to store in a cell, nil by default.
    def initialize(sizex=4, sizey=4, def_value=nil)
      @grid = []

      # Default Grid size is 4x4.
      sizex = 4 if not sizex.is_a?(Fixnum) or sizex.nil?
      sizey = 4 if not sizey.is_a?(Fixnum) or sizey.nil?

      @size_x = sizex
      @size_y = sizey

      @def_value = def_value

      # Build the grid and insert the default values.
      @size_x.times do |x|
        @grid.push([])
        @size_y.times do |y|
          @grid[x].push(def_value)
        end
      end
    end

  public

    # This checks to see if a given x,y pair are within
    # the boundries of the grid.
    def is_valid?(x, y)

      if (not x.is_a?(Fixnum) or x.nil?) or (not y.is_a?(Fixnum) or y.nil?)
        return false
      end

      if (x >= 0 and x < @size_x) and (y >= 0 and y < @size_y)
        return true
      else
        return false
      end

    end

    # Gets the data in a given x,y cell.
    # Returns nil if the cell is not valid.
    def get_cell(x, y)
      return @grid[x][y] if is_valid?(x, y)
    end

    # This method will return a set of cell data in a table.
    # The 'cells' argument should be an array of x,y pairs of
    # the cells being requested.
    def get_cells(cells) # :yields: cell_data
      data = []

      return data if not cells.is_a?(Array)

      cells.each do |x, y|
        if is_valid?(x, y)

          if block_given?
            yield @grid[x][y]
          else
            data.push(@grid[x][y])
          end

        end
      end

      return block_given? ? nil : data

    end

    # Sets a given x,y cell to the data object.
    def set_cell(x, y, obj)
      if is_valid?(x, y)
        @grid[x][y] = obj
      end
    end

    # Resets a given x,y cell to the grid default value.
    def reset_cell(x, y)
      if is_valid?(x, y)
        @grid[x][y] = @def_value
      end
    end

    # Resets the entire grid to the default value.
    def reset_all()
      @size_x.times do |x|
        @size_y.times do |y|
          @grid[x][y] = @def_value
        end
      end
    end

    # This method is used to populate multiple cells at once.
    # +data+::
    #   This argument must be an array, with each element 
    #   consisting of three values: x, y, and the data to set
    #   the cell too.
    #
    # Example:
    #
    #   d = [[{4, 4, "X"], [4, 5, "O"], [5, 4, "O"], [5, 5, "X"]]
    #   grid.populate(d)
    # 
    # If the object to be populated is nil, it is replaced with
    # the default value.
    def populate(data)
      return if not data.is_a?(Array)

      data.each do |x, y, obj|
        if is_valid?(x, y)
          obj = @def_value if obj.nil?
          @grid[x][y] = obj
        end
      end
      return
    end

    # This method returns the entire grid's contents in a
    # flat array suitable for feeding to populate() above.
    # Useful for recreating a grid layout.
    # If the +no_default+ argument is non-false, then the 
    # returned data array only contains elements who's 
    # cells are not the default value.
    # Returns +nil+ if a block is given.
    def get_contents(no_default=false) # :yields: x, y, cell_data
      data = []
      cell_obj = nil

      @size_x.times do |x|
        @size_y.times do |y|
          cell_obj = @grid[x][y]
          unless no_default and cell_obj == @def_value
            if block_given?
              yield x, y, cell_obj
            else
              data.push([x, y, cell_obj])
            end
          end
        end
      end

      return block_given? ? nil : data

    end

    # Convience method to return an x,y vector pair from the
    # GRID_* vector constants. Or nil if there is no such
    # constant.
    def get_vector(vector)
      case vector
        when TOP_LEFT     then return -1, -1
        when TOP          then return -1, 0
        when TOP_RIGHT    then return -1, 1
        when LEFT         then return 0, -1
        when CENTER       then return 0, 0
        when RIGHT        then return 0, 1
        when BOTTOM_LEFT  then return 1, -1
        when BOTTOM       then return 1, 0
        when BOTTOM_RIGHT then return 1, 1
      else
        return nil, nil
      end
    end

    # Gets a cell's neighbor in a given vector.
    def get_neighbor(x, y, vector)
      vx, vy = get_vector(vector)
      if vx and vy
        x = x + vx
        y = y + vy
        return @grid[x][y] if is_valid?(x, y)
      end
    end

    # Will return an array of 8 elements, with each element
    # representing one of the 8 neighbors for the given
    # x,y cell. Each element of the returned array will consist
    # of the x,y cell pair, plus the data stored there, suitable
    # for use of the populate method. If the neighbor cell is 
    # outside the grid, then [nil, nil, OUTSIDE] is used 
    # for that value.
    # If the given x,y values are not sane, an empty array
    # is returned instead.
    def get_neighbors(x, y) # :yields: x, y, cell_data
      data = []
      return data if not is_valid?(x, y)

      # The vectors used are x,y pairs between -1 and +1
      # for the given x,y cell. 
      # IE: 
      # (-1, -1) (0, -1) (1, -1)
      # (-1,  0) (0,  0) (1,  0)
      # (-1,  1) (0,  1) (1,  1)
      # Value of 0,0 is ignored, since that is the cell
      # we are working with! :D
      for gx in -1..1
        for gy in -1..1
          vx = x + gx
          vy = y + gy
          unless gx == 0 and gy == 0
            if is_valid?(vx, vy)
              if block_given?
                yield vx, vy, @grid[vx][vy]
              else
                data.push([vx, vy, @grid[vx][vy]])
              end
            else
              if block_given?
                yield nil, nil, OUTSIDE
              else
                data.push([nil, nil, OUTSIDE])
              end
            end
          end
        end
      end
      return block_given? ? nil : data
    end

    # This method will change the grid size. If the new size is
    # smaller than the old size, data in the cells now 'outside'
    # the grid is lost. If the grid is now larger, new cells are
    # filled with the default value given when the grid was first
    # created.
    def resize(newx, newy)
      if (not newx.is_a?(Fixnum) or newx.nil?) or (not newy.is_a?(Fixnum) or newy.nil?)
        return false
      end

      # Save old data.
      c = get_contents()

      # Reset grid.
      @grid.clear()
      @size_x = newx
      @size_y = newy

      newx.times do |x|
        @grid.push([])
        newy.times do |y|
          @grid[x].push(@def_value)
        end
      end

      populate(c)

      return true
    end

    # This method returns an array of all values in a given 
    # row 'x' value.
    # If given a block, then the data in each cell in the row
    # is passed to the block.
    def get_row(x) # :yields: cell_data
      row = []
      if x.is_a?(Fixnum) and (x >= 0 and x < @size_x)
        row = @grid[x]
      end

      if block_given?
        row.each do |obj|
          yield obj
        end
      end
      return block_given? ? nil : row
    end

    # This method returns an array of all values in a given
    # column 'y' value.
    # If given a block, then the data in each cell in the column
    # is passed to the block.
    def get_column(y) # :yields: cell_data
      col = []
      if y.is_a?(Fixnum) and (y >= 0 and y < @size_y)
        @size_x.times do |x|
          if block_given?
            yield @grid[x][y]
          else
            col.push(@grid[x][y])
          end
        end
      end

      return block_given? ?  nil : col

    end

    # This method traverses a line of cells, from a given x,y 
    # going in +vector+ direction. The vector arg is one of the
    # Grid::* traversal constants. This will return an array of 
    # data of the cells along the traversal path or nil if 
    # the original x,y is not valid or if the vector is not one
    # of the constant values. The first element of the array 
    # will be the first cell -after- the x, y cell given as the
    # argument.
    # In the returned array, each element will be in the format 
    # of [x, y, obj], suitable for populate().
    # If a block is given, then each x, y, and data is passed to
    # the block, and nil is returned.
    def traverse(x, y, vector) # :yields: x, y, cell_data
      data = []

      if is_valid?(x, y)
        vx, vy = get_vector(vector)
        return data if vx.nil?

        gx = x + vx
        gy = y + vy

        while is_valid?(gx, gy)
          obj = @grid[gx][gy]
          if block_given?
            yield gx, gy, obj
          else
            data.push([gx, gy, obj])
          end
          gx = gx + vx
          gy = gy + vy
        end
      end

      return block_given? ? nil : data
    end

  end

  # Wrapper for GridBase.new()
  def Grid.create(x, y, value)
    return GridBase.new(x, y, value)
  end

  # Yields each of the vector constants in turn, from top-left
  # to bottom-right.
  def Grid.get_all_vectors() # :yields: vector_constant
    [TOP_LEFT, TOP, TOP_RIGHT, LEFT, CENTER, RIGHT,
      BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT].each do |v|
        yield v # :yields: vector_constant
    end
  end

end
