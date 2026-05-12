package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strings"

import rl "vendor:raylib"

in_range :: proc(x1, y1, x2, y2, radius: f32) -> bool {
	return math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2) < math.pow(radius, 2)
}

WIDTH :: 800
HEIGHT :: 500
MOVE_SPEED :: 300

main :: proc() {
	rl.InitWindow(WIDTH, HEIGHT, "Drop")
	rl.InitAudioDevice()
	bucketTexture := rl.LoadTexture("bucket.png")
	bucketWidth, bucketHeight := f32(bucketTexture.width), f32(bucketTexture.height)
	dropTexture := rl.LoadTexture("drop.png")
	dropWidth, dropHeight := f32(dropTexture.width), f32(dropTexture.height)
	backgroundTexture := rl.LoadTexture("background.png")
	music := rl.LoadMusicStream("music.mp3")
    dropSound := rl.LoadSound("drop.mp3")

	playerX: f32 = 0
	score: i32 = 0
	accumulatedTime: f32 = 0
	drops := [dynamic][2]f32{}
	rl.SetMusicVolume(music, 0.8)
	rl.SetMusicPan(music, 0.0)

	rl.PlayMusicStream(music)
	for !rl.WindowShouldClose() {
		// Update
		rl.UpdateMusicStream(music)
		dt := rl.GetFrameTime()
		accumulatedTime += dt
		if rl.IsKeyDown(.RIGHT) {
			playerX += MOVE_SPEED * dt
		}
		if rl.IsKeyDown(.LEFT) {
			playerX -= MOVE_SPEED * dt
		}

		if rl.IsMouseButtonDown(.LEFT) {
			mousePosition := rl.GetMousePosition()
			playerX = mousePosition.x - bucketWidth * 0.5
		}
		playerX = rl.Clamp(playerX, 0, WIDTH - bucketWidth)

		if accumulatedTime >= 1 {
			accumulatedTime = 0
			// Add a new drop
			xValue := rand.float32_range(0, HEIGHT - dropWidth)
			append(&drops, [2]f32{xValue, 0})

		}

		#reverse for &value, index in drops {
			value.y += MOVE_SPEED * dt
			if value.y > 700 {
				unordered_remove(&drops, index)
			}

			if in_range(
				playerX + bucketWidth * 0.5,
				HEIGHT - bucketHeight * 0.5,
				value.x + dropWidth * 0.5,
				value.y + dropHeight * 0.5,
				bucketHeight,
			) {
				score += 1
                rl.PlaySound(dropSound)
				unordered_remove(&drops, index)
			}
		}

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		// Draw background
		rl.DrawTextureRec(backgroundTexture, {0, 0, WIDTH, HEIGHT}, {0, 0}, rl.WHITE)
		for value, index in drops {
			rl.DrawTextureV(dropTexture, value, rl.WHITE)
		}
		rl.DrawTextureV(bucketTexture, {playerX, HEIGHT - f32(bucketTexture.height)}, rl.WHITE)
		scoreText := fmt.tprintf("%d", score)
		rl.DrawText(strings.clone_to_cstring(scoreText, allocator=context.temp_allocator), 10, 10, 32, rl.BLACK)
		rl.EndDrawing()

		// Clear every temporary allocation each frame.
		// The game is so small we don't have to worry about accidentally using freed memory.
		free_all(context.temp_allocator)
	}
	rl.UnloadMusicStream(music)
	rl.CloseAudioDevice()
	rl.CloseWindow()

}
