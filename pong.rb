require "rubygems"
require "gosu"

WIDTH = 640
HEIGHT = 360
FOREGROUND = Gosu::Color.new(0xFF31DE31)
BACKGROUND = Gosu::Color.new(0xFF000000)
FLASH = Gosu::Color.new(0x7fFF0000)

class MatchField
  LINE_POSITION = WIDTH / 2
  
  def draw(frame)
    frame.draw_line(LINE_POSITION, 0, FOREGROUND,
                    LINE_POSITION, HEIGHT, FOREGROUND)
  end
end

class Player
  PONG_HEIGHT = HEIGHT / 5
  PONG_HEIGHT_HALF = PONG_HEIGHT / 2
  PONG_WIDTH = 10
  PONG_WIDTH_HALF = PONG_WIDTH / 2
  PONG_SPEED = 4.5

  def initialize(x_position)
    @y_position = HEIGHT / 2
    @x_position = x_position
  end

  def move_up
    if @y_position > PONG_HEIGHT_HALF
      @y_position -= PONG_SPEED
    end
  end

  def move_down
    if @y_position < HEIGHT - PONG_HEIGHT_HALF
      @y_position += PONG_SPEED
    end
  end

  def x_position
    @x_position
  end

  def y_position
    @y_position
  end

  def draw(frame)
    frame.draw_quad(@x_position - PONG_WIDTH_HALF, @y_position - PONG_HEIGHT_HALF, FOREGROUND,
                    @x_position + PONG_WIDTH_HALF, @y_position - PONG_HEIGHT_HALF, FOREGROUND,
                    @x_position - PONG_WIDTH_HALF, @y_position + PONG_HEIGHT_HALF, FOREGROUND,
                    @x_position + PONG_WIDTH_HALF, @y_position + PONG_HEIGHT_HALF, FOREGROUND)
  end
end

class Ball
  LEFT = true
  RIGHT = false
  BALL_HEIGHT = 10
  BALL_HEIGHT_HALF = BALL_HEIGHT / 2
  BALL_WIDTH = 10
  BALL_WIDTH_HALF = BALL_WIDTH / 2
  BALL_SPEED = 5
  MAX_X_POSITION = WIDTH - BALL_WIDTH_HALF
  MAX_Y_POSITION = HEIGHT - BALL_HEIGHT_HALF
  RADIANT = Math::PI / 180
  ANGLE_INC = 10

  def initialize(player_left, player_right, score, 
                 ping_sample, pong_sample, out_sample)
    center
    @direction = LEFT
    @player_left = player_left
    @player_right = player_right
    @score = score
    @ping_sample = ping_sample
    @pong_sample = pong_sample
    @out_sample = out_sample
  end

  def center
    @x_position = WIDTH / 2
    @y_position = HEIGHT / 2
    @angle = rand(44) + 1
  end

  def collision_detection
    # wall detection
    if @x_position <= BALL_WIDTH_HALF
      touch_left
    end

    if @x_position >= MAX_X_POSITION
      touch_right
    end

    if @y_position <= BALL_HEIGHT_HALF
      @y_position = BALL_HEIGHT_HALF
      touch_top
    end

    if @y_position >= MAX_Y_POSITION
      @y_position = MAX_Y_POSITION
      touch_bottom
    end

    # player detection
    if @direction == LEFT
      x_hit_line = @player_left.x_position + Player::PONG_WIDTH_HALF
      y_begin = @player_left.y_position - Player::PONG_HEIGHT_HALF
      y_end = @player_left.y_position + Player::PONG_HEIGHT_HALF

      new_ball_position_x = @x_position - BALL_SPEED
      
      if new_ball_position_x < x_hit_line
        new_ball_position_y = @y_position - y_move

        gradient = (@y_position - new_ball_position_y) /
                   (@x_position - new_ball_position_x)

        n = @y_position - (gradient * @x_position)

        target_y = gradient * x_hit_line + n

        if (y_begin..y_end) === target_y
          @x_position = x_hit_line + BALL_WIDTH_HALF
          @y_position = gradient * @x_position + n
        
          @angle += (@angle < 0) ? ANGLE_INC * -1 : ANGLE_INC
        
          flip_direction
        end
      end
    else
      x_hit_line = @player_right.x_position - Player::PONG_WIDTH_HALF
      y_begin = @player_right.y_position - Player::PONG_HEIGHT_HALF
      y_end = @player_right.y_position + Player::PONG_HEIGHT_HALF

      new_ball_position_x = @x_position + BALL_SPEED
      if new_ball_position_x > x_hit_line
        new_ball_position_y = @y_position + y_move

        gradient = (new_ball_position_y - @y_position) /
                   (new_ball_position_x - @x_position)

        n = @y_position - (gradient * @x_position)

        target_y = gradient * x_hit_line + n

        if (y_begin..y_end) === target_y
          @x_position = x_hit_line - BALL_WIDTH_HALF
          @y_position = gradient * @x_position + n
        
          @angle += (@angle < 0) ? ANGLE_INC * -1 : ANGLE_INC
        
          flip_direction
        end
      end
    end
  end

  def touch_left
    center
    flip_direction
    @score.score_up_right
    @out_sample.play
  end

  def touch_right
    center
    flip_direction
    @score.score_up_left
    @out_sample.play
  end

  def turn_angle
    @angle = @angle * -1
    @pong_sample.play
  end

  def touch_top
    turn_angle
  end

  def touch_bottom
    turn_angle
  end

  def y_move 
    Math.tan(RADIANT * @angle) * BALL_SPEED
  end

  def move
    ### collision detection system ###
    collision_detection

    ### normal ball movement ###
    if @direction == LEFT
      @x_position -= BALL_SPEED
    else
      @x_position += BALL_SPEED
    end
    @y_position += y_move
  end

  def flip_direction
    @direction = ! @direction
    @ping_sample.play
  end

  def draw(frame)
    frame.draw_quad(@x_position - BALL_WIDTH_HALF, @y_position - BALL_HEIGHT_HALF, FOREGROUND,
                    @x_position + BALL_WIDTH_HALF, @y_position - BALL_HEIGHT_HALF, FOREGROUND,
                    @x_position - BALL_WIDTH_HALF, @y_position + BALL_HEIGHT_HALF, FOREGROUND,
                    @x_position + BALL_WIDTH_HALF, @y_position + BALL_HEIGHT_HALF, FOREGROUND)
  end
end

class Score
  FLASH_DURATION = 7
  SCORE_POSITION = 10

  def initialize(font)
    @font = font
    @score_left = 0
    @score_right = 0
    @flash = 0
  end

  def score_up_left
    @score_left += 1
    @flash = FLASH_DURATION
  end

  def score_up_right
    @score_right += 1
    @flash = FLASH_DURATION
  end

  def draw(frame)
    num_left = @score_left.to_s
    num_right = @score_right.to_s
    
    # left
    x = WIDTH / 4 - @font.text_width(num_left) / 2
    @font.draw(num_left, x, SCORE_POSITION, 1, 1, 1, FOREGROUND)

    # right
    x = WIDTH / 4 * 3 - @font.text_width(num_right) / 2
    @font.draw(num_right, x, SCORE_POSITION, 1, 1, 1, FOREGROUND)
    
    # flash
    if @flash > 0
      frame.draw_quad(0, 0, FLASH,
                      WIDTH, 0, FLASH,
                      0, HEIGHT, FLASH,
                      WIDTH, HEIGHT, FLASH)

      @flash -= 1
    end
  end
end

class PongGame < Gosu::Window
  def initialize
    super(WIDTH, HEIGHT, false)
    @font = Gosu::Font.new(self, "Verdana", HEIGHT / 10)
    @out = Gosu::Sample.new(self, "out.wav")
    @pong = Gosu::Sample.new(self, "pong.wav")
    @ping = Gosu::Sample.new(self, "ping.wav")
    @field = MatchField.new
    @score = Score.new(@font)
    @player_left = Player.new(15)
    @player_right = Player.new(WIDTH - 15)
    @ball = Ball.new(@player_left, @player_right, @score, @ping, @pong, @out)
    self.caption = "Pong v0.2"
  end

  def draw
    @field.draw(self)
    @score.draw(self)
    @player_left.draw(self)
    @player_right.draw(self)
    @ball.draw(self)
  end

  def update
    # end game on escape
    if button_down?(Gosu::KbEscape)
      close
    end

    if button_down?(Gosu::KbUp)
      @player_right.move_up
    end
    if button_down?(Gosu::KbDown)
      @player_right.move_down
    end
    if button_down?(Gosu::KbW)
      @player_left.move_up
    end
    if button_down?(Gosu::KbS)
      @player_left.move_down
    end

    @ball.move
  end
end

game = PongGame.new
game.show

