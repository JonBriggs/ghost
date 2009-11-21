class Player < Chingu::GameObject
    has_trait :bounding_box, :scale => 0.90
    has_traits :velocity, :collision_detection, :timer, :effect
    attr_reader :max_steps, :facing
    
    def initialize(options)
      super
        
      @max_steps = 30
      @speed = 3
        
      @image = Image["player.png"]
      self.alpha = 100
      @status = :dead
      @dtheta = 0
      @y_anchor = @y
        
      # banisterfiend
      @facing = :right
      
      @cooling_down = false
        
      self.input = {
        [:holding_a, :holding_left, :holding_pad_left] => :left, 
        [:holding_d, :holding_right, :holding_pad_right] => :right, 
        [:holding_w, :holding_up, :holding_pad_up] => :up,
        [:holding_s, :holding_down, :holding_pad_down] => :down,
        [:gamepad_button_2, :space, :f] => :fire
      }
      
      self.rotation_center = :center
    end
      
    def hit_by(object)
      self.alpha = 50
      Sound["swing.wav"].play(0.4)
      during(500) { @x -= 3; self.factor += 0.01 }.then { self.factor = 1; self.alpha = 100}      
    end
    
    def fire
      return if @cooling_down
      @cooling_down = true
      after(500) { @cooling_down = false }
      
      Sound["swosh.wav"].play
      
      if $window.firepower == 1
        Bullet.create(:x => @x, :y => @y, :facing => facing)
      elsif $window.firepower == 2
        Bullet.create(:x => @x, :y => @y, :facing => facing)
        Bullet.create(:x => @x, :y => @y-60, :facing => facing)
      elsif $window.firepower == 3
        Bullet.create(:x => @x, :y => @y-60, :facing => facing)
        Bullet.create(:x => @x, :y => @y, :facing => facing)
        Bullet.create(:x => @x, :y => @y+60, :facing => facing)
      end
    end
    
    
    def up
      return if collisions_top?
      @velocity_y = -@speed
      @y_anchor += @velocity_y
    end

    def down
      return if collisions_bottom?
      @velocity_y = @speed
      @y_anchor += @velocity_y
    end

    def left
      @facing = :left
      return if collisions_left?
      @velocity_x = -@speed
    end
    
    def right
      @facing = :right
      return if collisions_right?
      @velocity_x = @speed 
    end

    Collision_Step = 15

    def collisions_left?
        bg = $window.current_game_state 

        (0..@image.height).step(Collision_Step) do |dy| 
                return true if bg.pixel_collision_at?(self.bb.left - 25, self.bb.top + dy)
        end
        false
    end

    def collisions_right?
        bg = $window.current_game_state

        (0..@image.height).step(Collision_Step) do |dy|
            return true if bg.pixel_collision_at?(self.bb.right + 25, self.bb.top + dy)
        end
        false
    end

    def collisions_top?
        bg = $window.current_game_state
        
        (0..@image.width).step(Collision_Step) do |dx|
            return true if bg.pixel_collision_at?(self.bb.left + dx, self.bb.top - 25)
        end
        false
    end

    def collisions_bottom?
        bg = $window.current_game_state

        (0..@image.width).step(Collision_Step) do |dx|
            return true if bg.pixel_collision_at?(self.bb.left + dx, self.bb.bottom + 25)
        end
        false
    end
      
    def update        
        # Slow down the playermovement to a halt when dead
        @velocity_x *= 0.90 if @velocity_x.abs <= @speed
        @velocity_y *= 0.90 if @velocity_y.abs <= @speed
        
        #
        # Make the ghost "float" up and down when idle
        #
        if @velocity_x.abs < 0.1 and @velocity_y.abs < 0.1
          @dtheta = (@dtheta + 5) % 360
          @dy = 5 * Math::sin(@dtheta / 180.0 * Math::PI)
          @y = @y_anchor + @dy  unless (@dy > 0 && collisions_top?) || (@dy < 0 && collisions_bottom?)
        else
          @dtheta = 0
          @y_anchor = @y
        end        
                
        # Make sure player-image is turned correctly, use GOSUs draw_rot argument factor_x to achieve this
        # Dont modify when scaling
        if @factor_x.abs == 1
          @factor_x = (@velocity_x >= 0) ? 1 : -1 
        end
        
    end
end

class Bullet < Chingu::GameObject
  has_traits :collision_detection, :timer, :bounding_box
  
  def initialize(options)
    super
    @image = Image["enemy_ghost_bullet.png"]
    rotation_center(:center)
    @direc = options[:facing] == :left ? -1 : 1
  end

  def hit_by(object)
    during(50) { self.factor += 1; self.alpha -= 10; }.then { destroy }
  end
  
  def update
    @x += 3 * @direc
  end
  
end


class AlivePlayer < Chingu::GameObject
    has_traits :velocity, :effect, :collision_detection, :timer, :bounding_box
    attr_reader :max_steps
    attr_accessor :status
    
    def initialize(options)
        super
        
        self.rotation_center(:center_bottom)    
        @max_steps = 10
        @speed = 2
        @dt = 0
        @dt_max = 200
        
        @image_alive_1 = Image["player_alive_1.png"]
        @image_alive_2 = Image["player_alive_2.png"]   
        @image = @image_alive_1
        
        @status = :default
        @last_direction = :left
        @factor_x = -1
        self.acceleration_y = 0.3 # gravity!
        self.input = { 
          [:holding_left, :holding_a, :holding_pad_left] => :left, 
          [:holding_right, :holding_d, :holding_pad_right] => :right 
        }
    end
    
    def left
        @x -= @speed
        @last_direction = :left
        @status = :walking
        handle_collision
    end
    
    def right
        @x += @speed
        @last_direction = :right
        @status = :walking
        handle_collision
    end
        
    def handle_collision
        if $window.current_game_state.pixel_collision_at?(@x, @y)
            steps = $window.current_game_state.distance_to_surface(@x, @y)
            if steps  < @max_steps
                @y -= steps
                stop
            else
                @x = @last_x
                self.acceleration_y = 0.3 # gravity!
            end
        end
    end
    
    def update    
        @last_x, @last_y = @x, @y   # Move this to trait "velocity"
        
        handle_collision
        
        # Simple animation between 2 pictures when "alive"
        if @status == :walking
            @dt += $window.dt
            if @dt > @dt_max
                @image = (@image == @image_alive_1) ? @image_alive_2 : @image_alive_1
                @dt = 0
            end
        end
        
        @status = :default
        
        # Make sure player-image is turned correctly, use GOSUs draw_rot argument factor_x to achieve this
        @factor_x = (@last_direction == :right) ? 1 : -1 
    end  
end
