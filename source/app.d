import std.stdio;
import polyplex;
import polyplex.math;
import polyplex.core.window;
import polyplex.core.input;
import polyplex.core.game;
import polyplex.core.color;
import polyplex.core.render;
import polyplex.core.content.textures;
import derelict.sdl2.sdl;
import polyplex.utils;
import std.conv;

void main(string[] args)
{
	try
	{
		LogLevel |= LogType.Info;
		LogLevel |= LogType.Debug;
		ChosenBackend = GraphicsBackend.Vulkan;
		if (args.length == 2)
		{
			if (args[1] == "-vulkan")
			{
				ChosenBackend = GraphicsBackend.Vulkan;
			}
			else if (args[1] == "-opengl")
			{
				ChosenBackend = GraphicsBackend.OpenGL;
			}
		}
		Logger.Info("Set rendering backend to {0}...", ChosenBackend);
		do_launch();
	}
	catch (Exception ex)
	{
		Logger.Info("Application failed! {0}", ex);
	}
}

void do_launch()
{
	try
	{
		if (ChosenBackend == GraphicsBackend.Vulkan)
		{
			try
			{
				InitLibraries();
				MyGame game = new MyGame();
				game.Run();
			}
			catch
			{
				Logger.Recover("Going to OpenGL fallback mode...");
				ChosenBackend = GraphicsBackend.OpenGL;
				do_launch();
			}
		}
		else
		{
			InitLibraries();
			MyGame game = new MyGame();
			game.Run();
		}
	}
	catch (Error err)
	{
		Logger.Log("Fatal Error! {0}", err, LogType.Fatal);
	}
}

import polyplex.core.render.gl.objects;

class MyGame : Game
{
	private Texture2D texture;
	private Vector2 position;

	this()
	{
		WindowInfo inf = new WindowInfo();
		inf.Name = "My Game";
		inf.Bounds = Rectangle(0, 0, 1080, 720);
		super(inf);
	}

	public override void Init()
	{
		texture = LoadTexture2DTemp("test.png");
		position = Vector2(0f, 0f);
	}

	public override void Update(GameTimes* game_time)
	{
		if (Input.IsKeyDown(KeyCode.KeyW)) {
			position.Y -= 1f;
		} else if (Input.IsKeyDown(KeyCode.KeyS)) {
			position.Y += 1f;
		}

		if (Input.IsKeyDown(KeyCode.KeyA)) {
			position.X -= 1f;
		} else if (Input.IsKeyDown(KeyCode.KeyD)) {
			position.X += 1f;
		}
	}

	public override void Draw(GameTimes* game_time)
	{
		Drawing.ClearColor(Color.CornflowerBlue);
		sprite_batch.Begin();
		sprite_batch.Draw(texture, Rectangle(cast(int)position.X, cast(int)position.Y, 128, 128), Rectangle(0, 0, texture.Width/2, texture.Height/2), Color.White);
		sprite_batch.End();
	}
}
