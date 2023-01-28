use context essentials2021
# CS 12 21.2 MP 
# Calubayan and Solas
# NOTE: The game may lag at first play (at the first transition to be specific) because some of the background images are being loaded from an online source. Based on our tests, consequent plays will have no stutters once the images have been loaded.

import reactors as R
import image as I

### TYPES ###

data PlatformLevel:
  | top
  | middle
  | bottom
end

data GameStatus:
  | ongoing
  | transitioning(ticks-left :: Number)
  | game-over
end

type Platform = {
  x :: Number,
  y :: Number,
  dx :: Number,
}

type Egg = {
  x :: Number,
  y :: Number,
  dx :: Number,
  dy :: Number,
  ay :: Number,
  is-airborne :: Boolean,
}

type Background = {
  y :: Number,
  dy :: Number,
  bg-image :: Image
}

type State = {
  game-status :: GameStatus,
  egg :: Egg,
  top-platform :: Platform,
  mid-platform :: Platform,
  bot-platform :: Platform,
  current-platform :: PlatformLevel,
  other-platforms :: List<Platform>,
  score :: Number,
  lives :: Number,
  bg :: Background,
  other-bgs :: List<Background>,
}


### CONSTANTS ###

FPS = 60

SCREEN-WIDTH = 300
SCREEN-HEIGHT = 500
SCREEN-COLOR = "light-sky-blue"
LIVES-COLOR = "fire-brick"
SCORE-COLOR = "ivory"

EGG-RADIUS = 20
EGG-COLOR = 'navajo-white'
EGG-COLOR-HIT = "red"
EGG-JUMP-HEIGHT = -14 # test muna
g = 0.5 # acceleration due to gravity

PLAT-WIDTH = 60
PLAT-HEIGHT = 10
PLAT-COLOR = 'brown'

PLAT-MAX-X = SCREEN-WIDTH - PLAT-WIDTH # ACTUAL MAX: (SCREEN-WIDTH - (PLAT-WIDTH / 2))
PLAT-MAX-DX = 4 # ACTUAL MAX: 5

TOP-PLAT-X = num-random(PLAT-MAX-X) + (PLAT-WIDTH / 2)
TOP-PLAT-Y = ((SCREEN-HEIGHT + PLAT-HEIGHT) * 0.25)
TOP-PLAT-DX = num-random(PLAT-MAX-DX) + 2

MID-PLAT-X = num-random(PLAT-MAX-X) + (PLAT-WIDTH / 2)
MID-PLAT-Y = ((SCREEN-HEIGHT + PLAT-HEIGHT) * 0.50)
MID-PLAT-DX = num-random(PLAT-MAX-DX) + 2

BOT-PLAT-X = num-random(PLAT-MAX-X) + (PLAT-WIDTH / 2)
BOT-PLAT-Y = ((SCREEN-HEIGHT + PLAT-HEIGHT) * 0.75)
BOT-PLAT-DX = num-random(PLAT-MAX-DX) + 2

BOT-TO-TOP-Y = BOT-PLAT-Y - TOP-PLAT-Y # Distance from top platform to bottom

PLAYER-LIVES = 12

TRANSITION-TIME = 2 * FPS

BACKGROUND-INTERVAL = 4
# Background changes every n points. Must be even and n >= 2

### Initial background ###
cloud = overlay-xy(overlay-xy(circle(10, "solid", "ivory"), 15, 0, 
    circle(10, "solid", "ivory")), -8, 10, 
  overlay-xy(circle(10, "solid", "ivory"), 15, 0, 
    overlay-xy(circle(10, "solid", "ivory"), 15, 0, 
      circle(10, "solid", "ivory"))))

cloud-1 = put-image(scale(2, cloud), 80, 300 , empty-scene(SCREEN-WIDTH, SCREEN-HEIGHT))

cloud-2 = put-image(scale(2, cloud), 200, 350 , empty-scene(SCREEN-WIDTH, SCREEN-HEIGHT))

cloud-scene = overlay(cloud-1, cloud-2)

a = {y: SCREEN-HEIGHT / 2,
  dy: 0,
  bg-image: cloud-scene
}

EGG = {
  x: BOT-PLAT-X,
  y: BOT-PLAT-Y - (EGG-RADIUS + (PLAT-HEIGHT / 2)),
  dx: BOT-PLAT-DX,
  dy: 0,
  ay: 0,
  is-airborne: false,
  color: EGG-COLOR
}

INITIAL-STATE = {
  game-status: ongoing,
  egg: EGG,
  top-platform: {x: TOP-PLAT-X, y: TOP-PLAT-Y, dx: TOP-PLAT-DX },
  mid-platform: {x: MID-PLAT-X, y: MID-PLAT-Y, dx: MID-PLAT-DX },
  bot-platform: {x: BOT-PLAT-X, y: BOT-PLAT-Y, dx: BOT-PLAT-DX },
  current-platform: bottom,
  other-platforms: [list: ],
  score: 0,
  lives: PLAYER-LIVES,
  bg: a,
  other-bgs: [list: ],
}


### DRAWING ###

fun draw-sun-hills(state :: State, img :: Image) -> Image:
  doc: "Draws the sun and hills on the first few 'levels', and mars at the 'end' of the game. for cosmetic purposes."
  sun = overlay(circle(50, "solid", "orange"), star-polygon(50, 10, 3, "solid", "yellow"))

  sun-scene = put-image(sun, 0, SCREEN-HEIGHT, 
    empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, "transparent"))

  hills = overlay-xy(isosceles-triangle(200, 120, "solid", "light-green"), 150, -30, 
    overlay-xy(isosceles-triangle(200, 100, "solid", "sea-green"), 100, 30, 
      isosceles-triangle(200, 120, "solid", "dark-green")))

  hills-scene = put-image(hills, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 8, 
    empty-scene(SCREEN-WIDTH, SCREEN-HEIGHT))

  members = text-font("by Calubayan and Solas", 15, "black", "Comic Sans", "script", "normal", "normal", false) 

  members-scene = put-image(members, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 16, empty-scene(SCREEN-WIDTH, SCREEN-HEIGHT))

  # score-backdrop = image-url("https://i.imgur.com/CykQNNP.png")
  sun-and-hills = overlay(members-scene, overlay(hills-scene, sun-scene))
  mars = image-url("https://i.imgur.com/1aX8v1r.png")
  
  if state.score < (BACKGROUND-INTERVAL * 3):
    I.place-image(sun-and-hills, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 2, img)
  else if state.score >= (BACKGROUND-INTERVAL * 10):
    I.place-image(mars, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 2, img)
  else:
    img
  end
end

fun draw-background(state :: State, img :: Image) -> Image:
  doc: "Draws the bg and motion of bg for cosmetic purposes."
  if state.other-bgs.length() > 0:
    current = I.place-image(state.bg.bg-image, SCREEN-WIDTH / 2, state.bg.y, img)
    next = state.other-bgs.get(0)
    I.place-image(next.bg-image, SCREEN-WIDTH / 2, next.y, current)
  else:
    I.place-image(state.bg.bg-image, SCREEN-WIDTH / 2, state.bg.y, img)
  end
end

fun draw-egg(state :: State, img :: Image) -> Image:
  egg = circle(EGG-RADIUS, "solid", state.egg.color)
  I.place-image(egg, state.egg.x, state.egg.y, img)
end

fun draw-platform(platform :: Platform, img :: Image) -> Image: 
  plat = rectangle(PLAT-WIDTH, PLAT-HEIGHT, 'solid', PLAT-COLOR)
  place-image-align(plat, platform.x, platform.y, 'center', 'center', img)
end

fun draw-new-platforms(state :: State, img :: Image) -> Image:
  cases (GameStatus) state.game-status:
    | ongoing => img
    | game-over => img
    | transitioning(ticks-left) => state.other-platforms.foldr(draw-platform(_, _), img)
  end
end

fun draw-score(state :: State, img :: Image) -> Image:
  text-img = text-font(num-to-string(state.score), 36, SCORE-COLOR, "Comic Sans", "script", "normal", "bold", false)

  alt-text-img = text-font(num-to-string(state.score), 36, "black", "Comic Sans", "script", "normal", "bold", false)

  text-with-outline = overlay-xy(text-img, 3, 2, alt-text-img)
  
  I.place-image(text-with-outline, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 8, img)
end

fun draw-lives(state :: State, img :: Image) -> Image:
  lives-backdrop = overlay(rectangle(140, 20, "outline", "brown"), rectangle(140, 20, "solid", "peach-puff"))
  text-img = overlay-align('center', 'center', text-font("Lives remaining: " + num-to-string(state.lives), 15, LIVES-COLOR, "Comic Sans", "script", "normal", "bold", false), lives-backdrop)
  I.place-image(text-img, SCREEN-WIDTH / 1.3, SCREEN-HEIGHT / 25, img)
end

fun draw-game-over(state :: State, img :: Image) -> Image:
  cases (GameStatus) state.game-status:
    | ongoing => img
    | transitioning(ticks-left) => img
    | game-over =>
      text-img = text("GAME OVER", 48, "red")
      I.place-image(text-img, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 2, img)
  end
end

fun draw-handler(state :: State) -> Image:
  canvas = empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, SCREEN-COLOR)

  canvas
    ^ draw-background(state, _)
    ^ draw-sun-hills(state, _)
    ^ draw-platform(state.top-platform, _)   
    ^ draw-platform(state.mid-platform, _)
    ^ draw-platform(state.bot-platform, _)
    ^ draw-new-platforms(state, _)
    ^ draw-egg(state, _)
    ^ draw-score(state, _)
    ^ draw-lives(state, _)
    ^ draw-game-over(state, _)
end


### KEYBOARD ###

fun key-handler(state :: State, key :: String) -> State:
  cases (GameStatus) state.game-status:
    | ongoing => 
      #Conditional that prevents mid-air jumps
      if (state.egg.is-airborne == false) and (key == ' '):
        new-egg = state.egg.{ay: g}.{dy: EGG-JUMP-HEIGHT}.{is-airborne: true}
        state.{egg: new-egg}
      else:
        state
      end
    | transitioning(ticks-left) => state
    | game-over => INITIAL-STATE
  end
end


### TICKS ###

fun update-egg-y(state :: State) -> State: 
  doc: "vertical velocity of egg when airborne"
  if state.egg.is-airborne == true:
    new-egg = state.egg.{y: state.egg.y + state.egg.dy}
    state.{egg: new-egg}
  else:
    state
  end
end

fun update-egg-dy(state :: State) -> State: 
  doc: "vertical acceleration of egg when airborne"
  if state.egg.is-airborne == false:
    state
  else:
    new-egg = state.egg.{dy: state.egg.dy + state.egg.ay}
    state.{egg: new-egg}
  end
end

fun update-egg-x(state :: State) -> State: #horizontal velocity
  doc: "horizontal velocity of egg when on platform (changes direction with platform)"
  if state.egg.is-airborne == false:
    new-egg = state.egg.{x: state.egg.x + state.egg.dx}
    state.{egg: new-egg}
  else:
    state
  end
end

fun update-egg-dx(state :: State) -> State: 
  doc: "Matches velocity of egg to the velocity of its current platform"
  cases (PlatformLevel) state.current-platform:
    | bottom =>
      new-egg = state.egg.{dx: state.bot-platform.dx}
      state.{egg: new-egg}
    | middle =>
      new-egg = state.egg.{dx: state.mid-platform.dx}
      state.{egg: new-egg}
    | top =>
      new-egg = state.egg.{dx: state.top-platform.dx}
      state.{egg: new-egg}
  end
end

fun update-egg-collision(state :: State) -> State:
  doc: 'Updates egg interaction'

  egg-top = state.egg.y - EGG-RADIUS
  is-beyond-screen-bot = egg-top >= SCREEN-HEIGHT


  fun is-landing-on-plat(plat :: Platform) -> Boolean:
    half-plat-height = PLAT-HEIGHT / 2
    half-plat-width = PLAT-WIDTH / 2

    egg-dist-x = num-abs(state.egg.x - plat.x)
    egg-dist-y = num-abs(state.egg.y - plat.y)

    #|
    if (egg-dist-x <= half-plat-width) and (egg-dist-y == (plat.y - (half-plat-height + EGG-RADIUS))):
      true
    else:
      false
    end
    |#

    if egg-dist-x > (half-plat-width):
      false
    else if egg-dist-y > (half-plat-height + EGG-RADIUS):
      false
    else if egg-dist-x <= (half-plat-width):
      true
    else if egg-dist-y <= (half-plat-height + EGG-RADIUS):
      true
    else:
      cor-dist-sqr = num-sqr(egg-dist-x - half-plat-width) + num-sqr(egg-dist-y - half-plat-height)
      (cor-dist-sqr <= num-sqr(EGG-RADIUS))      
    end

  end

  fun next-plat(game-state :: State) -> Platform:
    doc: "Assigns the next platform based on current platform"
    cases (PlatformLevel) game-state.current-platform:
      | top => game-state.bot-platform
      | middle => game-state.top-platform
      | bottom => game-state.mid-platform
    end
  end

  fun next-level(game-state :: State) -> PlatformLevel:
    doc: "Assigns the next platform level based on current platform level"
    cases (PlatformLevel) game-state.current-platform:
      | top => bottom
      | middle => top
      | bottom => middle
    end
  end

  is-landing-on-next-plat = is-landing-on-plat(next-plat(state))

  if is-beyond-screen-bot:
    if state.lives == 1: 
      state.{game-status: game-over, lives: state.lives - 1}
    else:
      #cases place the egg at the center of its previous platform and subtracts one life
      cases (PlatformLevel) state.current-platform:
        | top =>
          new-egg = state.egg.{
            x: state.top-platform.x,
            y: state.top-platform.y - (EGG-RADIUS + (PLAT-HEIGHT / 2)),
            dx: state.top-platform.dx,
            dy: 0,
            ay: 0,
            is-airborne: false,
            color: EGG-COLOR}
          state.{egg: new-egg, lives: state.lives - 1}
        | middle =>
          new-egg = state.egg.{
            x: state.mid-platform.x,
            y: state.mid-platform.y - (EGG-RADIUS + (PLAT-HEIGHT / 2)),
            dx: state.mid-platform.dx,
            dy: 0,
            ay: 0,
            is-airborne: false,
            color: EGG-COLOR}
          state.{egg: new-egg, lives: state.lives - 1}
        | bottom =>
          new-egg = state.egg.{
            x: state.bot-platform.x,
            y: state.bot-platform.y - (EGG-RADIUS + (PLAT-HEIGHT / 2)),
            dx: state.bot-platform.dx,
            dy: 0,
            ay: 0,
            is-airborne: false,
            color: EGG-COLOR}
          state.{egg: new-egg, lives: state.lives - 1}
      end
    end

  else if is-landing-on-next-plat: #Sets vert. velocity to zero after landing on the platform
    if state.egg.dy > 0: 
      #Conditional prevents the egg from "colliding" with platforms from below
      new-egg = state.egg.{
        y: (next-plat(state).y - (EGG-RADIUS + (PLAT-HEIGHT / 2))), 
        dx: next-plat(state).dx,
        dy: 0,
        ay: 0,
        is-airborne: false}
      state.{egg: new-egg, current-platform: next-level(state), score: state.score + 1}
    else:
      state
    end
  else:
    state
  end
end

fun update-plat-x(state :: State) -> State:    
  doc: "Updates all onscreen platform.x"
  state.{
    top-platform: 
      {x: state.top-platform.x + state.top-platform.dx,
        y: state.top-platform.y,
        dx: state.top-platform.dx,
      },
    mid-platform: 
      {x: state.mid-platform.x + state.mid-platform.dx,
        y: state.mid-platform.y,
        dx: state.mid-platform.dx,
      },
    bot-platform: 
      {x: state.bot-platform.x + state.bot-platform.dx,
        y: state.bot-platform.y,
        dx: state.bot-platform.dx,
      },
  }
end

fun update-plat-dx(state :: State) -> State:
  doc: "Updates platform.dx if platform touches edges of screen width"

  fun is-hitting-width-edge(platform :: Platform) -> Boolean:
    ((platform.x + platform.dx) < (PLAT-WIDTH / 2)) or ((platform.x + platform.dx) > (SCREEN-WIDTH - (PLAT-WIDTH / 2)))
  end

  if is-hitting-width-edge(state.top-platform): 
    state.{top-platform: 
        {x: state.top-platform.x,
          y: state.top-platform.y,
          dx: -1 * state.top-platform.dx,
        }
    }
  else if is-hitting-width-edge(state.mid-platform): 
    state.{mid-platform: 
        {x: state.mid-platform.x,
          y: state.mid-platform.y,
          dx: -1 * state.mid-platform.dx,
        }
    }
  else if is-hitting-width-edge(state.bot-platform): 
    state.{bot-platform: 
        {x: state.bot-platform.x,
          y: state.bot-platform.y,
          dx: -1 * state.bot-platform.dx,
        }
    }
  else:
    state
  end
end

fun update-level(state :: State) -> State:
  doc: 'Allows game to transition to the next level'
  if state.current-platform == top:
    state.{game-status: transitioning(TRANSITION-TIME)}
  else:
    state
  end
end

fun update-transition(state :: State) -> State:
  doc: 'Handles game when game-status is transitioning'

  object-dy = BOT-TO-TOP-Y / TRANSITION-TIME # Distance y from top to bottom over the transition time

  fun update-plat-y(platform :: Platform) -> Platform:
    platform.{y: platform.y + object-dy}
  end

  fun generate-new-platforms() -> List<Platform>:
    new-mid-plat = {x: num-random(PLAT-MAX-X) + (PLAT-WIDTH / 2), y: (MID-PLAT-Y - BOT-TO-TOP-Y), dx: num-random(PLAT-MAX-DX) + 2}
    new-top-plat = {x: num-random(PLAT-MAX-X) + (PLAT-WIDTH / 2), y: (TOP-PLAT-Y - BOT-TO-TOP-Y), dx: num-random(PLAT-MAX-DX) + 2}

    [list: new-mid-plat, new-top-plat]
  end

  fun generate-new-background() -> List<Background>:
    doc: "Assigns next background to be overlayed off-screen, on top of the current bg"
    fun background-selector() -> Image:
      doc: "Picks out bg image based on state.score"
      b = image-url("https://i.imgur.com/gN2nGL2.png")
      c = image-url("https://i.imgur.com/EZxA1jL.png")
      d = image-url("https://i.imgur.com/D41Ix5y.png")
      e = image-url("https://i.imgur.com/f58X3tv.png")
      f = image-url("https://i.imgur.com/FSUHSLW.png")
      gg = image-url("https://i.imgur.com/a2nTu7m.png")
      h = image-url("https://i.imgur.com/v0FTq5X.png")
      i = image-url("https://i.imgur.com/3VJ7b4N.png")
      j = image-url("https://i.imgur.com/CVXbrYY.png")
      k = image-url("https://i.imgur.com/H6Vz5eP.png")
      l = image-url("https://i.imgur.com/bWIecXa.png")
      stars-one = image-url("https://i.imgur.com/quQZpmF.png")
      stars-two = image-url("https://i.imgur.com/pF5bFmy.png")
        

      score = state.score

      fun score-bounds(min :: Number, max :: Number) -> Boolean:
        scoree = state.score
        (scoree >= min) and (scoree < max)
      end

      if score-bounds(0, BACKGROUND-INTERVAL):
        b
      else if score-bounds(BACKGROUND-INTERVAL, BACKGROUND-INTERVAL * 2):
        c
      else if score-bounds(BACKGROUND-INTERVAL * 2, BACKGROUND-INTERVAL * 3):
        d
      else if score-bounds(BACKGROUND-INTERVAL * 3, BACKGROUND-INTERVAL * 4):
        e
      else if score-bounds(BACKGROUND-INTERVAL * 4, BACKGROUND-INTERVAL * 5):
        f
      else if score-bounds(BACKGROUND-INTERVAL * 5, BACKGROUND-INTERVAL * 6):
        gg
      else if score-bounds(BACKGROUND-INTERVAL * 6, BACKGROUND-INTERVAL * 7):
        h
      else if score-bounds(BACKGROUND-INTERVAL * 7, BACKGROUND-INTERVAL * 8):
        i
      else if score-bounds(BACKGROUND-INTERVAL * 8, BACKGROUND-INTERVAL * 9):
        j
      else if score-bounds(BACKGROUND-INTERVAL * 9, BACKGROUND-INTERVAL * 10):
        k
      else if score-bounds(BACKGROUND-INTERVAL * 10, BACKGROUND-INTERVAL * 11):
        stars-one
      else:
        randomizer = num-random(2)
        if randomizer == 0:
          stars-one
        else:
          stars-two
        end
      end
    end
    [list: {y: -1 * (SCREEN-HEIGHT / 2), dy: 0, bg-image: background-selector()}]
  end
  
  new-ticks-left = state.game-status.ticks-left - 1
  new-platforms = generate-new-platforms()
  new-bottom = state.top-platform
  new-BGs = generate-new-background()

  if state.game-status.ticks-left == TRANSITION-TIME:
    # Generate new platforms at the start of the transitioning phase
    # Happens only once
    if num-modulo(state.score, BACKGROUND-INTERVAL) == 0:
      state.{
        game-status: transitioning(new-ticks-left),
        other-platforms: new-platforms,
        other-bgs: new-BGs,
      }
    else:
      state.{
        game-status: transitioning(new-ticks-left),
        other-platforms: new-platforms,
      }
    end
  else if state.game-status.ticks-left > 0:
    # Everything becomes frozen
    # Move platforms down including new platforms
    if num-modulo(state.score, BACKGROUND-INTERVAL) == 0:
      next = state.other-bgs.get(0)
      state.{
        game-status: transitioning(new-ticks-left),
        egg: state.egg.{y: state.egg.y + object-dy},
        top-platform: update-plat-y(state.top-platform),
        mid-platform: update-plat-y(state.mid-platform),
        bot-platform: update-plat-y(state.bot-platform),
        other-platforms: state.other-platforms.map(update-plat-y),
        bg: state.bg.{y: state.bg.y + (object-dy * 2)},
        other-bgs: [list: next.{y: next.y + (object-dy * 2)}]
      }
    else:
      state.{
        game-status: transitioning(new-ticks-left),
        egg: state.egg.{y: state.egg.y + object-dy},
        top-platform: update-plat-y(state.top-platform),
        mid-platform: update-plat-y(state.mid-platform),
        bot-platform: update-plat-y(state.bot-platform),
        other-platforms: state.other-platforms.map(update-plat-y)
      }
    end
  else:
    # Revert state to ongoing game status
    # Revert current platform to bottom
    # Generated platforms become new mid-platform and top-platform respectively
    # Old top-platform becomes new bot-platform
    # Other platforms become cleared again
    if num-modulo(state.score, BACKGROUND-INTERVAL) == 0:
      state.{
        game-status: ongoing,
        top-platform: state.other-platforms.get(1),
        mid-platform: state.other-platforms.get(0),
        bot-platform: new-bottom,
        current-platform: bottom,
        other-platforms: [list: ],
        bg: state.other-bgs.get(0).{y: SCREEN-HEIGHT / 2},
        other-bgs: new-BGs,
      }
    else:
      state.{
        game-status: ongoing,
        top-platform: state.other-platforms.get(1),
        mid-platform: state.other-platforms.get(0),
        bot-platform: new-bottom,
        current-platform: bottom,
        other-platforms: [list: ],
      }
    end
  end
end


fun tick-handler(state :: State) -> State:
  cases (GameStatus) state.game-status:
    | ongoing =>   
      state
        ^ update-egg-dy(_)
        ^ update-egg-y(_)
        ^ update-plat-x(_)
        ^ update-egg-x(_)
        ^ update-plat-dx(_)
        ^ update-egg-dx(_)
        ^ update-egg-collision(_)
        ^ update-level(_)
    | transitioning(ticks-left) => 
      state
        ^ update-transition(_)
    | game-over => 
      state
  end
end


### MAIN ###

world = reactor:
  title: 'Egg Toss',
  init: INITIAL-STATE,
  to-draw: draw-handler,
  seconds-per-tick: 1 / FPS,
  on-tick: tick-handler,
  on-key: key-handler,
end

R.interact(world)

# Make ball bounce (only once) [DONE]
# Make platforms move (and make ball move with platform after landing) [DONE]
# Add collision; Make platform and ball interact [DONE]
# Generate platforms ("shift" after every two levels) [DONE]
# Add score and lives [DONE]
# Add game over; Restart [DONE]
# Remove off-screen platforms from game state (filter) [DONE]
# Searching and fixing bugs