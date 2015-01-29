# error in game class with reference to @ref. ref should be @ref

# mastermind

# TODO
# safe_array[] should be process_later[]
# half_half_color should be mask_color, what about other half_half stuff
# need to add a good top level comment explaining the algo simply. ie guess and process
# also the algo for determining the num of blacks and whites in referee

# With regression it is essential to make sure that it initially fails by inducing a failing (a la TDD)
# so that you can have confidence that regression is not giving you a false positive

# referee class that checks rules, determines blacks n whites, valid colors...
# codemaker class that creates code or acts as user
# codebreaker class that attempts to break code or acts as user
# game class that controls game loop

#4 positions to choose from
# #use an array of colors to hold code#

#generate method which builds 4 digit code from colors, repeating allowed

class Referee

  private

  #attr_accessor :code, :guess, :code_count
  attr_accessor :code_count
  attr_reader   :code, :guess

  public

  attr_writer   :guess

  VALID_COLORS = [:red, :purple, :green, :yellow, :blue, :orange]
  CODE_LENGTH  = 4

  def initialize
    @code = []
    @code_count = nil
    #puts "Referee.new called"
  end

  # every time you enter a new code, a new code_count must be created
  def code= (_code)
    @code = _code
    #@code_count = Hash.new(0)
    count_code
    #puts "Referee.code setter called"
  end

  def valid_code?(_code)
    return false if _code.length != 4
    _code.each { |color| return false unless VALID_COLORS.include?(color)}
    true
  end

# Purpose is to inspect codemaker's code and count each color's occurence in @code_count hash

# I don't believe that code_count[color] = value is using a setter. it is using the getter. the pointer to the
# hash is retrieved which is used to reference the hash and then insert the value in memory. the setter would be
# used in order to set the hash to a new hash. This makes sense. I should be able to make the hash only a getter
# and it should still work the same.

  def count_code
    self.code_count = Hash.new(0)
    code.each { |color| code_count[color] += 1 }
    #puts "Count code called"
  end

# iterate through code and guess, and count number of exact matches for each possible color and record in black_count hash
# for each color.
  def count_blacks
    black_count = Hash.new(0)
    code.length.times { |i| black_count[code[i]] += 1 if code[i] == guess[i]  } ## DRT
    black_sum = 0
    black_count.each { |k,v| black_sum += v }
    black_sum
  end

#how to determine number of whites, color match but not position match
# iterate through guess and add to total_correct_guess_count if current total_correct_guess_count is not == code_count
# total_correct_guess_count is the number of correct colors in the guess
# NUM_OF_WHITES returns number of whites, called from submit
# uses black_guess_count from NUM_BLACKS method. this info is needed in this method.
  def count_correct_colors
    total_correct_color_count = Hash.new(0)
    guess.length.times do |i|
      total_correct_color_count[guess[i]] += 1 if total_correct_color_count[guess[i]] < code_count[guess[i]]
    end
    total_correct_sum = 0
    total_correct_color_count.each { |k,v| total_correct_sum += v }
    total_correct_sum
  end

  def count_blacks_n_whites
    num_blacks = count_blacks
    num_correct_colors = count_correct_colors
    num_whites = num_correct_colors - num_blacks
    [num_blacks, num_whites]
  end

end # class Referee


class CodeMaker

  def initialize
    # not sure if there is anything to do here
  end

  def generate_code
  	code = []
  	Referee::CODE_LENGTH.times { code << Referee::VALID_COLORS[rand(Referee::VALID_COLORS.length)] }
  	code
  end

end

# loop through all colors placing all of same type, ie. red, red, red, red
# place these colors in safe_array to be used at later part of algorithm.
# continue until color is found that is not present in code ( at most 5 turns )
# continue running through remaining colors until all colors are accounted for but now using half/half pattern
# this should allow placement in match_left/match_right arrays
# now repeat process with elements that were encountered prior to finding not present color ( in safe_array )
class CodeBreaker

  def initialize
    # setting to true will display debug info
    @debug = false
    # keep track of colors that we have submitted as all 4's prior to finding no match all 4 code
    # we will need to iterate through these again
    @safe_array = []
    # keep track of colors in left half of code
    @match_left = []
    # keep track of colors in right half of code
    @match_right = []
    # i think i need to clone this array so that I can remove each element from it.
    @valid_colors = Referee::VALID_COLORS.dup
    # zero response code is the first guess with all same colors that returns Black=0 and White=0.
    # the guess algorithm will key on this.
    @zero_response_code_found = false
    # current color seleccted by guess algorithm
    @current_color = nil
    # this is the color found that returns Blacks=0 during initial phase of guess algorithm
    @half_half_color = nil
    # keep track of blacks found
    @num_correct_colors_found = 0
    # need to know if there are old colors to process in half-half phase
    #@final_four_turn = :first_try # valid values are :first_try,:second_try,:last_try
    @final_four_array = [:first_try, :second_try, :last_try]
    @final_four_whites = 0 # used in guess to determine code in final stages of algorithm
    @final_code = nil
    # during half_half mode, matches of 2 of a kind are placed here to check if 3 of a kind
    # also 3 of a kind matches are placed here prior to zero_response being found
    @three_of_a_kind_check_array = []
    # hash used to hold [num_blacks, num_whites] per color. Necessary to determine 3 of a kind scenario.
    @half_half_result = {}
    # used by guess to tell process how to treat result as reverse_half_half
    @three_of_a_kind_mode = false
    @debug_enabled = false
  end # def initialize

  def debug_on
    @debug_enabled = true
  end

  def debug
    puts "**************** CODEBREAKER DEBUG ******************"
    puts "num_correct_colors_found = #{@num_correct_colors_found}"
    puts "zero_response_code_found = #{@zero_response_code_found}"
    puts "current_color = #{@current_color}"
    puts "half_half_color = #{@half_half_color}"
    puts "half_half_result = #{@half_half_result}"
    puts "safe_array = #{@safe_array}"
    puts "match_left = #{@match_left}"
    puts "match_right = #{@match_right}"
    puts "three_of_a_kind_mode = #{@three_of_a_kind_mode}"
    puts "three_of_a_kind_check_array = #{@three_of_a_kind_check_array}"
    puts "final_four_array = #{@final_four_array}"
    puts "******************************************************"

  end

  # algorithm keeps state using array and hash data structures and closes in on target code
  def guess
    debug if @debug_enabled
    code = []
    if @zero_response_code_found || @valid_colors.empty? # empty check is necessary since not receiving response yet but in the future not, since code_found will go true prior to empty
      #Referee::CODE_LENGTH.times { code << Referee::VALID_COLORS[rand(Referee::VALID_COLORS.length)] } REFACTOR
      # for example build [:red :red :blue :blue]
      if @num_correct_colors_found < 4 || !@safe_array.empty? # empty check can be removed since num_.._colors doesn't increment DRT
      
        # give priority to the safe_array first, then priority to the three_of_kind array, and then look into the remaining element array
        # the three_of_a_kind_array depends on the safe_array being processed first
        if @safe_array.empty? && !@three_of_a_kind_check_array.empty?
      
          #puts "reverse_half_half mode"
          @current_color = @three_of_a_kind_check_array.shift
          code << @current_color << @current_color << @half_half_color << @half_half_color
          # message to process
          @three_of_a_kind_check = true

        else

          # half-half phase -- ie. red, red, other_color, other_color
          # we may have found 4 valid colors in code but some valid colors are in safe_array still
          code << @half_half_color << @half_half_color
          # send a message to process method to process safe_array and not double count things
          #NOT NEEDED@process_safe_array_mode = !@safe_array.empty?
          # update @current_color with next in available colors or take color from safe_array
          @current_color = @safe_array.empty? ? @valid_colors.shift : @safe_array.shift
          code << @current_color << @current_color

        end # if @three_of_a_kind_check_array.empty?

      else # if @three_of_a_

        # At this point we have all the info we need for narrowing in on final placement
        final_turn = @final_four_array.shift # = [:first_try, :second_try, :last_try]
        if final_turn == :first_try
          code = @match_left + @match_right # do I need to worry about reference issues here - No tested on irb
          @final_code = code
        elsif final_turn == :second_try
          if @final_four_whites == 4
            code = [ @final_code[1], @final_code[0], @final_code[3], @final_code[2] ]
          else # has to be 2 whites
            code = [ @final_code[0], @final_code[1], @final_code[3], @final_code[2] ]         
          end
        else # to get here it has to be 2 whites -- need to verify this
            code = [ @final_code[1], @final_code[0], @final_code[2], @final_code[3] ]         
        end

      end

    else
      # looking for zero response
      @current_color = @valid_colors.shift
      Referee::CODE_LENGTH.times { code << @current_color }
    end
    code
  end # def guess

  # method will look at num of blacks and whites
  def process(num_blacks, num_whites) 
    if (!@zero_response_code_found)
      # we can only get blacks during this phase of all 4's same color however we will count them later during mask phase
      # keep track of number of exact matches
      if num_blacks > 0
        # save for later processing when we go to half/half mode
        @safe_array << @current_color
        #puts "color_count[#{@current_color}] = #{@color_count[@current_color]}"
        #puts "AA"
      else
        @zero_response_code_found = true
        @half_half_color = @current_color
        #puts "BB"
      end # if num_blacks
    else
      if @num_correct_colors_found < 4
        #puts "SEARCHING FOR FINAL 4"
        if @three_of_a_kind_check
# need to worry about 3 and 4 of a kind scenario
# during find zero-response phase - if we encounter 3 or 4 of a kind, we need to set a flag, perhaps my hash is doing that
#   or modify the hash.
# but then the problem comes about after finding the zero-response, during the finding the half-half phase. during this
#   phase it is not possible to determine if there are 3 or 4 of a kind due to the arrangemnet of the pattern.
# one way to solve this for both zero-response phase and half-half phase is by having another 3 of a kind safe array
# if during zero-response phase, we encounter 4 of a kind. game will auto end?
# if during zero-response phase, we encounter 3 of a kind, then submit color into three_of_a_kind array and into safe_array
# to be used later by guess method. guess will normally count the 2 on the right side, but not count the left. the 
# three_of_a_kind array and the half_half_left mode will count the 1 remaining color of a three of a kind
# if during half-half phase, we encounter 2 of a kind(specifically, 2 blacks, or 1 black/1 white, but not 2 whites, process
# will normally count the 2 colors. However there is a chance that there is a 3rd occurrence of the color that we can not see
# due to the half-half-right pattern. Therefore we need to add the color to the three_of_a_kind array which causes guess to
# change the pattern to
# [color, color, no-response-color, no-response-color]

# process needs to compensate for double counting whites (only count blacks) during 3_of_a_kind_check and for double
# counting doubles. (only count blacks when blacks+whites=3, whites have already been counted, and when blacks+whites==2,
# this scenario has already been counted)

# I need to save the state of the initial three_of_a_kind compare in order to determine how to count the three of a kind
# correctly.
          #puts "THREE OF A KIND CHECK IN PROCESS method"
          previous_num_blacks, previous_num_whites = @half_half_result[@current_color]
          if previous_num_blacks == 2
            #puts "PREVIOUS_NUM_BLACKS == 2"
            @num_correct_colors_found += num_blacks
            num_blacks.times { @match_left << @current_color }
          elsif previous_num_blacks == 1 && previous_num_whites == 1
            # for this case we need to make sure we don't double count
            #puts "PREV BLACKS==1 && PREV WHITES==1"
            if num_blacks == 2
              @num_correct_colors_found += 1
              @match_left << @current_color
            end
          end
          #puts "Num of blacks = #{num_blacks} Previous num blacks = #{previous_num_blacks}"
          #puts "Num of whites = #{num_whites} Previous num whites = #{previous_num_whites}"
          # always get out of three of a kind mode
          @three_of_a_kind_check = false

        else # if @three_of_a_kind_check
          # add to running total of found numbers so we can get to next phase of algo
          @num_correct_colors_found += (num_blacks + num_whites) ##### THIS WILL NEED TO CHANGE WHEN THREE OF A KIND LOGIC ADDED

          # following section is used in half-half section either by processing
          # new colors or by processing old colors from the safe array
          # if found blacks we found it on the right and update color_count for current_color
          # officially counting blacks and whites are only done while in half-half mode
          # note that safe_array take dequeue priority when it is not empty. see guess above
          if num_blacks > 0
            num_blacks.times { @match_right << @current_color } 
          end
          # if found whites we found it on the left and update color_count for current_color        
          if num_whites > 0
            num_whites.times { @match_left << @current_color } 
          end 
          # this info is necessary when doing the reverse half_half compare to see if there are three/four of a kind
          @half_half_result[@current_color] = [num_blacks, num_whites]
          # during this phase we can't know if there are 2 or 3 of the current color, so we need to do a reverse_half_half
          # check if there are 2 blacks or (1 black + 1 white)
          @three_of_a_kind_check_array << @current_color if (num_blacks == 2 || (num_blacks==1 && num_whites==1))
          #puts "CC"
        end # if @three_of_a_kind_mode else
      else
        # Scenarios are as follows for final code
        # L1,L2,R1,R2 
        # (4W)   -> L2,L1,R2,R1
        # (2W2B) -> L1,L2,R2,R1 or L2,L1,R1,R2
        # (0W)   -> pattern found
        #puts "DD"
        @final_four_whites = num_whites # used by guess

      end

    end # if !@zero_response...

  end # def process

end # class CodeBreaker


# top level class responsible for managing interactions between other classes
class Game

  def initialize
    puts "Game.new called"
  end

  def get_user_input(breaker_message,turn="")
      message = (breaker_message) ? "Turn #{turn}: " : ""
      puts "#{message}Enter #{Referee::CODE_LENGTH} valid colors separated by commas"
      input = gets.chomp.split(',').map(&:strip).map { |i| i.to_sym }
      while !(@ref.valid_code?(input)) 
        puts "INVALID GUESS ENTERED!! Please try again."
        p input
        puts "Turn #{turn}: Enter #{Referee::CODE_LENGTH} valid colors separated by commas"
        input = gets.chomp.split(',').map(&:strip).map { |i| i.to_sym }
      end # while !(@ref.valid_code?)
      input        
  end

  def user_selects_breaker?
    puts "Enter 1 to play as Code Breaker or enter 2 to play as Code Maker: "
    input = gets.chomp.to_i
    while input != 1 && input != 2
      puts "INVALID ENTRY!! Please try again."
      puts "Enter 1 to play as Code Breaker or enter 2 to play as Code Maker: "
      input = gets.chomp.to_i
    end
    (input == 1) ? true : false
  end

  def play
    # used to test out random combinations of computer CodeBreaker    
    regression = true #false

    repetition = (regression) ? 1000 : 1
    puts "Welcome to Mastermind!"
    puts "Running regression for #{repetition} times. On error, code will be displayed. Please wait." if regression

    repetition.times do
      # require a new referee for each game
      ref = Referee.new 
      code_maker = CodeMaker.new
      # need a new CodeBreaker so to reset all the state. we could add a reset method
      code_breaker = CodeBreaker.new      
      # comment the following line in order to turn off debug, gameplay or regression
      #code_breaker.debug_on
      turn = 1
      game_won = false
      code = code_maker.generate_code
      breaker_is_human = (regression) ? false : user_selects_breaker?
      puts "Choose from these valid colors:" unless regression
      Referee::VALID_COLORS.each { |i| print i.to_s + " "} unless regression
      puts unless regression
      code = get_user_input(false) unless (breaker_is_human || regression)
      ref.code = code

      while turn <= 12 && !game_won
        guess = breaker_is_human ? get_user_input(breaker_is_human, turn) : code_breaker.guess
        ref.guess = guess
        p guess unless regression
        num_blacks, num_whites = ref.count_blacks_n_whites
        print "Result for turn #{turn}: #{num_blacks} Blacks and #{num_whites} Whites\n\n" unless regression 
        game_won = true if num_blacks == 4
        code_breaker.process(num_blacks, num_whites) unless breaker_is_human
        turn += 1
      end # while turns
      
      puts game_won ? "The code has been broken!!" : "Sorry, the code was not broken. :(" unless regression
      p code if (!regression || (regression && !game_won))
      print "." if regression  ### output code if there is a failure    
    end # repetition.times
    puts

  end # def play


end

game = Game.new
game.play

