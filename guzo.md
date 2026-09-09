# GUZO — Multiplayer Educational Running Game

You are an expert Flutter/Dart game developer, Flame game-engine developer, mobile networking engineer, UI/UX designer, and multiplayer game architect.

I want you to help me build a production-quality mobile game called **GUZO**.

GUZO is an **offline multiplayer educational endless-running competition game for children**. It is inspired by the general gameplay style of endless running games such as Temple Run, but GUZO must have its own original gameplay, graphics, UI, characters, and branding.

The application must be built using:

- Flutter
- Dart
- Flame game engine
- Local Wi-Fi / mobile hotspot for multiplayer
- No internet requirement for multiplayer
- No Firebase for the core multiplayer system
- No cloud server for local multiplayer
- Android-first development, with architecture that can later support iOS

---

# 1. CORE GAME IDEA

GUZO means a running journey/competition.

Players compete against each other in a running race.

Each player controls a character that automatically runs forward.

During the race, players must:

1. Run
2. Avoid obstacles
3. Collect coins
4. Collect educational items
5. Collect letters/numbers in the correct sequence
6. Use coins for speed boosts
7. Reach the required sequence before the other players

The winner is the first player who correctly completes the required educational sequence.

Example:

A → B → C → D → E → ... → Z

The player cannot skip the sequence.

If the current target is C and the player collects D, D should not count.

---

# 2. EDUCATIONAL GAME MODES

GUZO must support multiple educational modes.

## Mode 1 — English Alphabet

The player must collect:

A → B → C → D → E → ... → Z

The UI should show progress.

Example:

A ✓
B ✓
C ✓
D →
E
F
...

The arrow indicates the current target.

---

## Mode 2 — Amharic Alphabet

Create an Amharic educational mode.

The system must support Amharic Fidel/letters and configurable sequences.

Example:

ሀ → ሁ → ሂ → ሃ → ሄ → ህ → ሆ

Then continue with the appropriate configured Amharic sequence.

IMPORTANT:

Do not hard-code the educational engine to English.

Create a reusable sequence system so that English, Amharic, numbers, and future educational modes can all use the same game logic.

---

## Mode 3 — Numbers

Support:

1 → 2 → 3 → 4 → ... → 100

The game should allow the sequence length to be configurable.

For example:

1–10
1–20
1–50
1–100

---

## Future Number Challenges

Design the architecture so future modes can support:

Even numbers:

2 → 4 → 6 → 8 → 10

Odd numbers:

1 → 3 → 5 → 7 → 9

Reverse counting:

100 → 99 → 98 → ...

Multiplication sequences.

Do not implement every advanced mode initially, but make the architecture extensible.

---

# 3. MULTIPLAYER

The most important feature is **offline local multiplayer**.

Players must be able to connect using the same:

- Mobile hotspot
- Wi-Fi network
- Local network

Internet must NOT be required.

Example:

Phone 1:
HOST

Phone 2:
PLAYER 2

Phone 3:
PLAYER 3

Phone 4:
PLAYER 4

Architecture:

HOST PHONE
|
| Local Wi-Fi / Hotspot
|
+---- Player 2
|
+---- Player 3
|
+---- Player 4

Start with support for:

2 players

Then:

4 players

Architect the networking layer so it can later support more players.

---

# 4. HOST AUTHORITATIVE ARCHITECTURE

The host must be authoritative.

Do NOT allow each client to independently determine important game results.

The host controls:

- Game start
- Countdown
- Game seed
- Level generation
- Player IDs
- Player state
- Educational sequence
- Valid item collection
- Coins
- Speed boost state
- Finish state
- Winner

Clients send player actions/state to the host.

The host validates important actions.

For example:

If player currently needs C:

Player sends:

collect C

Host verifies:

currentTarget == C

If true:

accept collection.

If false:

reject collection.

This prevents inconsistent game states.

---

# 5. NETWORKING

Create a clean networking abstraction.

Suggested structure:

lib/network/

game_server.dart
game_client.dart
network_message.dart
network_protocol.dart
connection_manager.dart

The implementation should use local networking such as TCP sockets or another appropriate local-network transport.

The networking layer must support:

- Host creation
- Client connection
- Player discovery/join
- Lobby
- Room/game ID
- Game start
- Player state updates
- Item collection events
- Coin updates
- Boost events
- Finish events
- Winner announcement
- Disconnect/reconnect handling

Use compact messages.

Example:

{
"type": "player_update",
"playerId": "player_2",
"x": 120.5,
"y": 350.2,
"velocity": 1.2
}

Collection:

{
"type": "collect_item",
"playerId": "player_2",
"itemId": "item_42",
"value": "C"
}

Boost:

{
"type": "speed_boost",
"playerId": "player_2"
}

Do not continuously send unnecessarily large game states.

---

# 6. ROOM SYSTEM

The host creates a room.

Example:

GUZO-4821

The host screen displays:

GUZO

Room Code:
GUZO-4821

Players:
1/4

Waiting for players...

Clients can enter the room code.

Example:

JOIN GAME

Room:
GUZO-4821

[ JOIN GAME ]

The architecture should also support local IP connection if room-code discovery is not available.

---

# 7. LOBBY

Create a polished multiplayer lobby.

Example:

GUZO

Room: GUZO-4821

Players:

🟢 Player 1 — Host
🟢 Player 2
🟢 Player 3
🟢 Player 4

4/4 Players

[ START GAME ]

Only the host can start the game.

The host should see when players join or leave.

---

# 8. SYNCHRONIZED COUNTDOWN

When the host starts:

3

2

1

GO!

The start time should be synchronized.

Do not simply call a local countdown independently on every phone.

The host should send an authoritative game-start event/time.

---

# 9. GAMEPLAY

The player automatically runs forward.

Controls should be simple and child-friendly.

Possible controls:

Swipe left → move left

Swipe right → move right

Swipe up → jump

Swipe down → slide

You may alternatively implement on-screen controls if they provide better usability.

The player should have:

- Running animation
- Jumping animation
- Sliding animation
- Collision animation
- Boost animation

---

# 10. ENDLESS RUNNING WORLD

Create an endless-running environment.

The game should continuously generate terrain/road segments.

Include:

- Road
- Grass/ground
- Trees
- Rocks
- Bridges
- Decorative objects
- Obstacles
- Coins
- Educational collectibles

Use procedural/randomized generation with a deterministic seed supplied by the host so multiplayer players see the same world.

IMPORTANT:

The same seed should generate the same level structure for all players.

---

# 11. OBSTACLES

Create multiple obstacles.

Examples:

- Rocks
- Logs
- Barriers
- Holes
- Trees
- Moving obstacles

The player must avoid them.

Collision should affect running speed or temporarily interrupt the player.

Do not make the game frustrating for children.

Difficulty should gradually increase.

---

# 12. EDUCATIONAL COLLECTIBLES

Educational objects should be visually clear.

For example:

A

B

C

Each item should be easy for a child to identify.

The current target should be visually highlighted.

Example:

CURRENT TARGET:

C

The C collectible can have:

- Glow
- Animation
- Floating effect
- Highlight ring

Incorrect items should be visually different but still collectable/avoidable.

---

# 13. COIN SYSTEM

Add collectible coins.

Example:

🪙

When collected:

coins += 1

Display:

🪙 25

Coins are local to the match/player unless a future persistent economy is added.

Do not require internet for the coin system.

---

# 14. SPEED BOOST

Players can spend coins to activate a speed boost.

Example:

10 coins

→

SPEED BOOST

The player gets:

+60% speed

for approximately:

5 seconds

After the duration:

speed returns to normal.

Create:

speed_boost.dart

The boost should include:

- Visual effect
- Sound effect
- Player trail
- Speed animation
- HUD indicator
- Remaining duration

Example HUD:

⚡ 3.2s

The host must synchronize the important boost state during multiplayer.

---

# 15. WINNING SYSTEM

The primary victory condition is educational completion.

Example:

Player 1:

A–Z complete

Player 2:

A–Y complete

Player 3:

A–W complete

Player 1 wins.

The host determines the official winner.

When a player completes the final required item:

The host announces:

PLAYER 1 WINS!

Then all clients transition to the result screen.

---

# 16. RESULT SCREEN

Create a beautiful result screen.

Example:

GUZO

🏆 YOU WIN!

Completed:
A–Z

Time:
02:31

Coins:
54

Position:

🥇 Player 1
🥈 Player 2
🥉 Player 3

Buttons:

[ PLAY AGAIN ]

[ HOME ]

---

# 17. HOME SCREEN

Create a modern child-friendly home screen.

GUZO

Learn • Run • Compete

Buttons:

[ QUICK PLAY ]

[ MULTIPLAYER ]

[ EDUCATIONAL MODES ]

[ SETTINGS ]

Use large buttons and clear icons.

---

# 18. GAME MODES SCREEN

Create:

SELECT MODE

🇬🇧 English Alphabet

🇪🇹 Amharic Alphabet

🔢 Numbers

🎯 Custom Challenge

Initially implement:

English Alphabet
Amharic Alphabet
Numbers 1–100

---

# 19. PLAYER SELECTION

Eventually allow players to select characters.

Example:

Choose Your Runner

Character 1
Character 2
Character 3
Character 4

The characters should have original designs.

Do not copy copyrighted characters from existing games.

---

# 20. VISUAL STYLE

GUZO should look:

- Colorful
- Modern
- Child-friendly
- Educational
- Fun
- High quality
- Smooth
- Clean

Use a bright adventure/running-game atmosphere.

Avoid making it visually identical to Temple Run.

GUZO must have its own identity.

---

# 21. AUDIO

Add:

- Background music
- Running sound
- Jump sound
- Coin sound
- Correct collection sound
- Incorrect collection feedback
- Boost sound
- Countdown sound
- Victory sound
- Collision sound

Allow sound/music to be disabled in settings.

---

# 22. PERFORMANCE

The game must run smoothly on affordable Android devices.

Optimize:

- Sprite loading
- Texture usage
- Object creation
- Object pooling
- Network messages
- Game loop
- Memory
- Garbage collection

Avoid creating unnecessary objects every frame.

Use Flame best practices.

Target smooth gameplay around 60 FPS where device hardware allows.

---

# 23. OFFLINE-FIRST

GUZO must work without internet.

The following should work offline:

- Single player
- Educational modes
- Game assets
- Coins during a match
- Multiplayer over local hotspot
- Settings
- Local player configuration

Do not make the core gameplay dependent on:

- Firebase
- Internet APIs
- Cloud servers
- Online authentication

---

# 24. DATA STORAGE

Use local storage for settings and simple local data.

Possible package:

shared_preferences

Store:

- Sound enabled
- Music enabled
- Selected character
- Selected language
- Game settings

Do not introduce a remote database unless there is a future requirement.

---

# 25. PROJECT STRUCTURE

Use a clean scalable architecture.

Suggested:

lib/

main.dart

app/
guzo_app.dart

screens/
home_screen.dart
mode_selection_screen.dart
create_game_screen.dart
join_game_screen.dart
lobby_screen.dart
game_screen.dart
result_screen.dart
settings_screen.dart

game/
guzo_game.dart
player.dart
obstacle.dart
collectible.dart
coin.dart
speed_boost.dart
world_generator.dart
collision_system.dart
game_controller.dart

models/
player_model.dart
game_model.dart
collectible_model.dart
room_model.dart

network/
game_server.dart
game_client.dart
network_message.dart
network_protocol.dart
connection_manager.dart

data/
english_letters.dart
amharic_letters.dart
numbers.dart

services/
audio_service.dart
storage_service.dart

utils/
constants.dart
game_utils.dart

assets/
images/
players/
obstacles/
collectibles/
coins/
backgrounds/
sounds/
music/

---

# 26. CODE QUALITY

Use:

- Null safety
- Strong typing
- Clean architecture
- Small reusable classes
- Clear naming
- Constants instead of magic numbers
- Enums where appropriate
- Error handling
- Logging for networking
- Comments only where useful

Avoid:

- Giant files
- Giant classes
- Duplicate logic
- Hard-coded educational sequences inside gameplay logic
- Global mutable state where unnecessary

---

# 27. IMPORTANT DEVELOPMENT RULE

DO NOT generate the entire application in one giant response.

Build the application incrementally.

Follow this exact order:

PHASE 1

1. Create Flutter project
2. Install Flame
3. Configure assets
4. Create basic GUZO app
5. Create home screen
6. Create game screen
7. Create Flame game

PHASE 2

8. Create player
9. Add running animation
10. Add movement
11. Add camera
12. Create road
13. Create endless world
14. Add obstacles
15. Add collision

PHASE 3

16. Add educational sequence engine
17. Add English A–Z
18. Add Amharic letters
19. Add numbers 1–100
20. Add collectible objects
21. Add progress HUD

PHASE 4

22. Add coins
23. Add speed boost
24. Add boost effects
25. Add sounds
26. Add result screen

PHASE 5

27. Create local network server
28. Create client
29. Host game
30. Join game
31. Room code
32. Lobby
33. Player discovery
34. Synchronized countdown

PHASE 6

35. Synchronize player movement
36. Synchronize collectibles
37. Synchronize coins
38. Synchronize boosts
39. Synchronize game state
40. Host-authoritative winner

PHASE 7

41. Polish UI
42. Character selection
43. Animations
44. Sound
45. Performance optimization
46. Android testing
47. Multiplayer testing
48. Release build

---

# 28. IMPORTANT RESPONSE RULE

When I ask you to implement a phase:

1. Explain briefly what we are building.
2. Give the exact terminal commands.
3. Give the exact folder/file structure.
4. Give complete code for each new/changed file.
5. Tell me exactly where each file goes.
6. Explain how to run it.
7. Explain how to test it.
8. Mention common errors and how to fix them.
9. Do not skip required files.
10. Do not give pseudo-code when I need working code.

If a package/API has changed, use the current stable API compatible with the project's Flutter/Dart version.

Do not randomly change the architecture between phases.

Always continue from the existing code.

---

# 29. TESTING

Every major phase must include tests.

For example:

Single-player:

- Player can run
- Player can move
- Player can jump
- Collision works
- Coins work
- A–Z sequence works
- Incorrect letters are rejected
- Final letter produces victory

Multiplayer:

- Host can create room
- Client can join
- Multiple clients can connect
- Players appear in lobby
- Countdown is synchronized
- Player positions synchronize
- Letter collection synchronizes
- Coins synchronize
- Boost synchronizes
- Winner is synchronized
- Disconnect is handled gracefully

---

# 30. FIRST TASK

Start with ONLY Phase 1.

Create the Flutter project:

flutter create guzo

Then:

cd guzo

Then install Flame:

flutter pub add flame

Then create the basic GUZO application.

Do not implement multiplayer yet.

Do not implement the entire game yet.

First make sure the Flutter + Flame foundation is working correctly.

After Phase 1 is complete, wait for my instruction before proceeding to Phase 2.

The final goal is a polished offline multiplayer educational running game called:

# GUZO

Tagline:

**Learn • Run • Compete** 🏃🎮📚

The game should feel like a real commercial children's educational game, not a simple demo.
