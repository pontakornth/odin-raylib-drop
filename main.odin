package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strings"

import rl "vendor:raylib"

in_range :: proc(x1, y1, x2, y2, radius: f32) -> bool {
	return math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2) < math.pow(radius, 2)
}

main :: proc() {
	rl.InitWindow(800, 500, "Drop")
	rl.InitAudioDevice()
	bucketTexture := rl.LoadTexture("bucket.png")
	dropTexture := rl.LoadTexture("drop.png")
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
			playerX += 300 * dt
		}
		if rl.IsKeyDown(.LEFT) {
			playerX -= 300 * dt
		}
		if rl.IsKeyPressed(.SPACE) {
			score += 1
		}
		playerX = rl.Clamp(playerX, 0, 800.0 - f32(bucketTexture.width))

		if accumulatedTime >= 1 {
			accumulatedTime = 0
			// Add a new drop
			xValue := rand.float32_range(0, 500 - f32(dropTexture.width))
			append(&drops, [2]f32{xValue, 0})

		}

		#reverse for &value, index in drops {
			value.y += 300 * dt
			if value.y > 700 {
				unordered_remove(&drops, index)
			}

			if in_range(
				playerX + f32(bucketTexture.width) * 0.5,
				500 - f32(bucketTexture.height) * 0.5,
				value.x + f32(dropTexture.width) * 0.5,
				value.y + f32(dropTexture.height) * 0.5,
				f32(bucketTexture.height),
			) {
				score += 1
                rl.PlaySound(dropSound)
				unordered_remove(&drops, index)
			}
		}

		// Draw
		rl.BeginDrawing()
		rl.ClearBackground({160, 200, 255, 255})
		// Draw background
		rl.DrawTextureRec(backgroundTexture, {0, 0, 800, 500}, {0, 0}, rl.WHITE)
		for value, index in drops {
			rl.DrawTextureV(dropTexture, value, rl.WHITE)
		}
		rl.DrawTextureV(bucketTexture, {playerX, 500 - f32(bucketTexture.height)}, rl.WHITE)
		scoreText := fmt.tprintf("%d", score)
		rl.DrawText(strings.clone_to_cstring(scoreText), 10, 10, 32, rl.BLACK)
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
	rl.UnloadMusicStream(music)
	rl.CloseAudioDevice()
	rl.CloseWindow()

}
