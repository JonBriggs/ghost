class Screen < Chingu::GameState
  has_trait :timer
  attr_reader :map, :player
  
  
  def initialize(options = {})
    super
    
    self.input = { :e => Chingu::GameStates::Edit, :f1 => :next_screen, :a => Screen15 }
    
    @image = options[:image] || "#{self.class.to_s.downcase}.png"
    @clouds = options[:clouds] || 15
    @enter_x = options[:enter_x] || 230
    @enter_y = options[:enter_y] || 380
    
    @background = GameObject.create(:image => @image, :zorder => 10, :rotation_center => :top_left)
    
    @game_states = Hash.new
    @width = 800
    @height = 600
        
    @player = Player.create(:x => @enter_x, :y => @enter_y, :zorder => 100)
    @sky1 = Color.new(0xFF510009)
    @sky2 = Color.new(0xFF111111)
    
    @clouds.times do |nr|
      Fog.create(:x => (nr-1) * ($window.width/@clouds) - 100, :y => $window.height - 70 - rand(50))
    end
    
    load_game_objects
  end
  
  def game_object_at(x, y)
    game_objects.select do |game_object| 
      game_object.respond_to?(:bounding_box) && game_object.bounding_box.collide_point?(x,y)
    end.first
  end
  
  def collision?(x, y)
    return false    if outside_window?(x, y)
    not @background.image.transparent_pixel?(x, y)
  end
  
  def outside_window?(x, y)    
    x <= 0 || x >= @background.image.width || y <= 0 || y >= @background.image.height
  end
  
  def distance_to_surface(x, y, max_steps = nil)
    steps = 0
    steps += 1  while collision?(x, y - steps) && (y - steps) > 0
    return steps
  end
  
  def next_screen
    switch_game_state(@game_states[:right].new(:enter_x => 1, :enter_y => @player.y))
  end
  
  def update
    super
    
    Fog.destroy_if { |fog| fog.right < 0 || fog.x > @width}
    Fog.create(:x => @width, :y => @height - 70 - rand(50)) if Fog.size < @clouds
      
    $window.caption = "Ghost. Screen: #{self.class.to_s}. FPS: #{$window.fps}. X/Y: #{@player.x}/#{@player.y}"
    
    if @player.x >= @width
      switch_game_state(@game_states[:right].new(:enter_x => 1, :enter_y => @player.y))
    elsif @player.x < 0
      switch_game_state(@game_states[:left].new(:enter_x => @width-1, :enter_y => @player.y))
    elsif @player.y > @height
      switch_game_state(@game_states[:down].new(:enter_x => @player.x, :enter_y => 1))
    elsif @player.y < 0
      # switch_game_state(@game_states[:up].new(:enter_x => @player.x, :enter_y => @height-1))
      @player.y = 0
    end
    
    @player.each_bounding_box_collision([EnemyGhost, EnemyGhostBullet]) do |me, enemy|
      @player.hit_by(enemy)
      enemy.hit_by(@player) if enemy.is_a? EnemyGhostBullet
    end
    
    # banisterfiend - destroys enemy bullet on terrain collision  
    EnemyGhostBullet.all.each { |bullet|
        if collision?(bullet.x, bullet.y)
            bullet.destroy

            # banisterfiend - terrain destruction
            @background.image.circle(bullet.x, bullet.y, 10, :color => :alpha, :fill => true)
        end
    }

    Bullet.each_bounding_box_collision([EnemyGhost, EnemySpirit]) do |bullet, enemy|
      enemy.hit_by(bullet)
      bullet.hit_by(enemy)
    end
    
    game_objects.destroy_if { |game_object| game_object.outside_window? }
    
  end
  
  def draw
    fill_gradient(:from => @sky2, :to => @sky1, :zorder => -1)    
    super
  end
  
end


class Screen1 < Screen
  def initialize(options = {})
    super
    @game_states[:right] = Screen2
    Song["wind.ogg"].play(true)
  end
  
  def setup
    #EnemySpirit.create(:x => 400)
  end
end

class Screen2 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen1
    @game_states[:right] = Screen3
  end

  def setup
    5.times do |nr|
      after(nr * 400) { EnemyGhost.create(:x => @width, :y => (nr+1) * 50 + rand(10)) }
    end
    EnemySpirit.create(:x => 600)
  end
end


class Screen3 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen2
    @game_states[:right] = Screen4
  end
  
  def setup
    EnemyGhost.create(:x => @width - 20, :y => 100)
    EnemyGhost.create(:x => @width - 60, :y => 200, :type => 2)
    EnemyGhost.create(:x => @width - 100, :y => 300)    
  end  
end


class Screen4 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen3
    @game_states[:right] = Screen5
  end
  
  def setup
    EnemyGhost.create(:x => @width, :y => 100)
    EnemyGhost.create(:x => @width - 20, :y => 200, :type => 2)
    EnemyGhost.create(:x => @width - 40, :y => 300, :type => 3)
  end
  
end


class Screen5 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen4
    @game_states[:right] = Screen6
  end
  
  def setup
    every(1500) { EnemyGhost.create(:x => @width, :y => 50 + rand(200)) }
  end
end


class Screen6 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen5
    @game_states[:right] = Screen7
  end
  
  def setup
    every(2000) { EnemyGhost.create(:x => @width, :y => 50 + rand(200), :type => 2) }
  end
end


class Screen7 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen6
    @game_states[:right] = Screen8
  end
  
  def setup
    EnemyGhost.create(:x => @width , :y => 50, :tpye => 2)
    EnemyGhost.create(:x => @width - 100, :y => 100, :tpye => 3)
    EnemyGhost.create(:x => @width - 100, :y => 150, :tpye => 3)
    EnemyGhost.create(:x => @width - 100, :y => 200, :tpye => 3)
    EnemyGhost.create(:x => @width - 100, :y => 300, :tpye => 2)
  end  
end


class Screen8 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen7
    @game_states[:right] = Screen9
  end
end


class Screen9 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen8
    @game_states[:right] = Screen10
  end
  
  def setup
    EnemySpirit.create(:x => @width - 50, :type => 1)
    EnemySpirit.create(:x => @width - 100, :type => 2)
    every(2000) { EnemySpirit.create(:x => rand(8) * 100, :type => 1) }
  end

end

class Screen10 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen9
    @game_states[:right] = Screen11
  end
  
  def setup
    EnemySpirit.create(:x => @width - 20, :type => 1)
    EnemySpirit.create(:x => @width - 200, :type => 3)
    every(3000) { EnemySpirit.create(:x => rand(8) * 100, :type => 2) }
  end  
end


class Screen11 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen10
    @game_states[:right] = Screen12
  end
  
  def setup
    EnemySpirit.create(:x => @width - 20, :type => 2)
    EnemySpirit.create(:x => @width - 100, :type => 2)
    EnemySpirit.create(:x => @width - 200, :type => 3)
    every(3000) { EnemySpirit.create(:x => rand(8) * 100, :type => 3) }
  end  
end


class Screen12 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen11
    @game_states[:right] = Screen13
  end
  
  def setup
  end  
end


class Screen13 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen12
    @game_states[:right] = Screen14
  end
  
  def setup
    EnemyGhost.create(:x => @width-20, :y => rand(@height)-100, :type => 3)
    EnemyGhost.create(:x => @width-50, :y => rand(@height)-100, :type => 3)
    EnemyGhost.create(:x => @width-100, :y => rand(@height)-100, :type => 3)
    every(2000) { EnemyGhost.create(:x => @width, :y => rand(@height)-100, :type => 3) }
    every(3000) { EnemySpirit.create(:x => rand(8) * 100, :type => 2) }
  end  
end


class Screen14 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen13
    @game_states[:right] = Screen15
  end
  
  def setup
  end  
end

class Screen15 < Screen
  def initialize(options = {})
    super
    @game_states[:left] = Screen13
    @game_states[:right] = Screen15
    
    @truck = GameObject.create( :x => $window.width,
                                :y => 300, 
                                :image => Image["truck.png"], 
                                :factor => 2,
                                :rotation_center => :left_bottom, 
                                :color => Color.new(0x99FFFFFF)
                              )
    @ghost = EnemyGhost.create(:x => $window.width + 50, :y => 100, :type => 3, :paused => true)
    
    @truck_endpoint = $window.width - 250
    @player_hit = false
  end
  
  def update
    
    if @player.x > @truck_endpoint && @truck.x > @truck_endpoint
      Sound["skid.ogg"].play  if @truck.x == $window.width
      
      @ghost.unpause!
      
      @truck.x -= 10
      @ghost.x -= 10
    end
        
    if @truck.x <= @truck_endpoint && @player_hit == false
      Sound["hit.wav"].play
      
      @player.input = nil
      @player_hit = true
      @player.velocity_x  = -6
      @player.velocity_y  = -4
      @player.rotation_rate = 8
      switch_game_state(GameStates::FadeTo.new(Alive1, :speed => 2))
      return
    end
    
    #if @player_hit && @player.outside_window?
    #if @player_hit && (@player.y < 10 || @player.x < 10)
    #end
    
    super 
  end
end
