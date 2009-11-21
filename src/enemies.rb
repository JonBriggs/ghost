class EnemyGhost < Chingu::GameObject
  has_traits :collision_detection, :timer, :bounding_box
  
  def initialize(options)
    super
    
    @type = options[:type] || 1
    @image = Image["enemy_ghost.png"]
    self.rotation_center = :center
    
    # We have 3 different kind of ghosts, defaults to type #1
    @color, @speed, @fire_rate = case @type
        when 1 then [Color.new(0xFFFF0000), 1, 2000]
        when 2 then [Color.new(0xFF00FF00), 2, 1500]
        when 3 then [Color.new(0xFFAA00AA), 2, 1000]
    end    
    
    @factor_x = -1              # Turn sprite left    
    every(@fire_rate) { fire }  # Fire a bullet every @fire_rate millisecond
  end
  
  def update
    @x -= @speed
  end
  
  def fire
    Sound["swosh.wav"].play
    bullet = EnemyGhostBullet.create(:x => self.bounding_box.left, :y => @y, :color => @color)
  end
  
  def hit_by(object)
    Sound["breath.wav"].play(0.5)
    during(250) { self.factor_y += 0.03; self.alpha -= 1; }.then { destroy }
  end  
  
end


class EnemySpirit < Chingu::GameObject
  has_traits :collision_detection, :timer, :bounding_box
  
  def initialize(options)
    super
    
    @type = options[:type] || 1
    @y = options[:y] || $window.height
    @x_anchor = @x
    @dtheta = rand(360)

    # amplitude of sine wave
    @amp = rand(7)
    
    @image = Image["enemy_spirit.png"]
    self.rotation_center = :center
    
    #
    # We have 3 different kind of spirits, defaults to type #1
    #
    if @type == 1
      @speed = 1
      @fire_rate = 4000
    elsif @type == 2
      @speed = 1
      @fire_rate = 3000
    elsif @type == 3
      @speed = 1
      @fire_rate = 2000
    end
    
    # Start out transparent, fade in
    self.alpha = 0
    during(1000) { self.alpha += 1}

    @factor_x = -1              # Turn sprite left    
    every(@fire_rate) { fire }  # Fire a bullet every @fire_rate millisecond
  end
  
  def update
    @dtheta = (@dtheta + 5) % 360
    @dx = @amp * Math::sin(@dtheta / 180.0 * Math::PI)
    @x = @x_anchor + @dx
    @y -= @speed
  end
  
  def fire
    Sound["swosh.wav"].play
    EnemyGhostBullet.create(:x => @x, :y => @y)
    
    if @type == 2
      EnemyGhostBullet.create(:x => @x, :y => @y, :y_offset => -150)
      EnemyGhostBullet.create(:x => @x, :y => @y, :y_offset => 150)
    elsif @type == 3
      EnemyGhostBullet.create(:x => @x, :y => @y, :y_offset => -250)
      EnemyGhostBullet.create(:x => @x, :y => @y, :y_offset => -150)
      EnemyGhostBullet.create(:x => @x, :y => @y, :y_offset => 150)
      EnemyGhostBullet.create(:x => @x, :y => @y, :y_offset => 250)
    end

  end
  
  def hit_by(object)
    Sound["breath.wav"].play(0.4)
    during(250) { self.factor_y += 0.03; self.alpha -= 1; }.then { destroy }
  end  
  
end



class EnemyGhostBullet < Chingu::GameObject
  has_traits :collision_detection, :velocity, :timer, :bounding_box
 
  def initialize(options)
    super
  
    @y_offset = options[:y_offset] || 0
    
    # velocity_x and velocity_y will be read by trait 'velocity' and applied to x and y
    self.velocity_x = ($window.current_game_state.player.x - @x) / 100
    self.velocity_y = ($window.current_game_state.player.y - @y + @y_offset) / 100
        
    @image = Image["enemy_ghost_bullet.png"]
    self.rotation_center(:center)
  end

  def hit_by(object)
    during(50) { self.factor += 1; self.alpha -= 10; }.then { destroy }
  end  
end
