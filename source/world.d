module example_game.world;
import example_game.player;
import example_game.enemy;
import example_game.block;
import example_game.app;
import polyplex.core.audio;
import polyplex.core;
import polyplex.math;
import polyplex.utils.logging;


public class World {
	private Camera2D camera;
	private Vector2 start_pos;

	public @property Rectangle WorldBounds() {
		return new Rectangle(0, 0, this.world_width*16, this.world_height*16);
	}

	private int world_height;
	private int world_width;
	public float CameraX = 0f;
	public float CameraY = 0f;
	public float CameraZoom = 3f;

	private int timeUniform;
	public Shader BlockShader;
	public Shader ScreenspaceWobble;
	public Block[] Blocks;
	public Enemy[] Enemies;
	public Player GamePlayer;

	public Music music;
	public Music music2;

	public BandpassFilter filter;
	public ReverbEffect reverbEf;

	public Framebuffer rendBuffer;
	public Texture2D backgroundScroller;

	this(int[][] blockids, Vector2 playerpos) {
		int height = cast(int)blockids.length;
		int width = cast(int)blockids[0].length;
		this.world_width = width;
		this.world_height = height;
		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				if (blockids[y][x] == 0) continue;
				if (blockids[y][x] == -1) {
					Enemies ~= new Enemy( Vector2(x*16, y*16), this);
					continue;
				}
				Blocks ~= new Block(blockids[y][x], Vector2(x*16, y*16));
			}
		}
		this.start_pos = playerpos;

		this.camera = new Camera2D(Vector2(0, 0));
		this.GamePlayer = new Player(Vector2(playerpos.X*16, (this.world_height*16)-(playerpos.Y*16)), this);
	}

	public void ResetStage() {
		CameraX = (Renderer.Window.ClientBounds.Width/2)/CameraZoom;
		GamePlayer.ResetState();
		foreach(Block b; Blocks) {
			b.ResetState();
		}
		foreach(Enemy e; Enemies) {
			e.ResetState();
		}
	}

	public void Unload() {
		destroy(music);
		destroy(music2);
		destroy(Blocks);
		destroy(Enemies);
		destroy(GamePlayer);
	}

	public void Init(ContentManager man) {
		Block.Reset();
		GamePlayer.Init(man.Load!Texture2D("player"), man.Load!SoundEffect("!in_content/jump.ogg"));
		Block.Init(man.Load!Texture2D("tiles"), GamePlayer);
		BlockShader = man.Load!Shader("shaders/block_shader");
		ScreenspaceWobble = man.Load!Shader("shaders/ss_wob");
		backgroundScroller = man.Load!Texture2D("example_bg");
		timeUniform = BlockShader.GetUniform("time");
		BlockShader.SetUniform(timeUniform, 0);
		Enemy.Init(man.Load!Texture2D("enemy_a"));
		ResetStage();
		filter = new BandpassFilter();
		filter.GainLow = 0f;
		filter.GainHigh = 0f;
		reverbEf = new ReverbEffect();
		reverbEf.Decay = 4f;


		music = man.Load!Music("music/arpeggio");
		music.Looping = true;
		music.Pitch = 1.3f;
		music.Gain = 0.7f;
		music.Filter = filter;
		music.Effect = reverbEf;
		//music.Play();
		
		music2 = man.Load!Music("music/mechanical_nightmare");
		music2.Looping = true;
		music2.Pitch = 1.0f;
		music2.Gain = 0f;
		music2.Filter = filter;
		music2.Play();

		rendBuffer = new Framebuffer(Renderer.Window.ClientBounds.Width, Renderer.Window.ClientBounds.Height);

	}

	public void Update(GameTime times) {
		BlockShader.SetUniform(timeUniform, cast(float)times.TotalTime.Milliseconds);
		ScreenspaceWobble.SetUniform(timeUniform, cast(float)times.TotalTime.Milliseconds);
		foreach(Block b; Blocks) {
			if (b is null) continue;
			b.Update(times);
		}
		GamePlayer.Update(times);
		this.camera.Origin = Vector2(Renderer.Window.ClientBounds.Width/2, Renderer.Window.ClientBounds.Height);
		this.camera.Zoom = CameraZoom;
		if (GamePlayer.Position.X > CameraX) {
			CameraX = GamePlayer.Position.X;
		}

		/*if (GamePlayer.Position.X > Renderer.Window.ClientBounds.Width) {

			if (music.Gain > 0) music.Gain = music.Gain - .005f;
			if (music.Gain < 0) music.Gain = 0f;
			if (music2.Gain < .3f) music2.Gain = music2.Gain + .005f;
			if (music2.Gain > .3f) music2.Gain = .3f;
		} else {
			if (music2.Gain > 0) music2.Gain = music2.Gain - .005f;
			if (music2.Gain < 0) music2.Gain = 0f;
			if (music.Gain < .7f) music.Gain = music.Gain + .005f;
			if (music.Gain > .7f) music.Gain = .7f;

		}*/

		CameraY = GamePlayer.Position.Y+128;
		if (CameraY > (world_height*16)) CameraY = (world_height*16);
		if (CameraX -(Renderer.Window.ClientBounds.Width/2)/CameraZoom < 0) CameraX = (Renderer.Window.ClientBounds.Width/2)/CameraZoom;
		this.camera.Position = Vector2(CameraX, CameraY);

		foreach(Enemy e; Enemies) {
			if (e is null) continue;
			e.Update(times);
		}
		import std.stdio;
		//writeln(music.Tell);
	}

	public void Draw(GameTime times, SpriteBatch batch) {
		// TODO: Make this only be used once the window actually resizes, it's a really bad idea to do this every frame.
		rendBuffer.Resize(Renderer.Window.ClientBounds.Width, Renderer.Window.ClientBounds.Height);

		Rectangle winBuff = new Rectangle(0, 0, Renderer.Window.ClientBounds.Width, Renderer.Window.ClientBounds.Height);
		Rectangle winBuffX = new Rectangle(cast(int)(CameraX+(times.TotalTime.Milliseconds/10f)), cast(int)(times.TotalTime.Milliseconds/10f), Renderer.Window.ClientBounds.Width, Renderer.Window.ClientBounds.Height);
	
		// Begin rendering to framebuffer.
		rendBuffer.Begin();
			batch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.PointWrap, RasterizerState.Default, BlockShader, null);
			batch.Draw(backgroundScroller, winBuff, winBuffX, 0f, Vector2.Zero, Color.Gray);
			batch.End();
			
			batch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.PointClamp, RasterizerState.Default, null, camera);
			GamePlayer.Draw(times, batch);

			foreach(Enemy e; Enemies) {
				if (e is null) continue;
				e.Draw(times, batch);
			}
			batch.End();

			batch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.PointClamp, RasterizerState.Default, null, camera);
			foreach(Block b; Blocks) {
				if (b is null) continue;
				b.Draw(times, batch);
			}
			batch.End();
		rendBuffer.End();

		// Draw the framebuffer to the screen.
		batch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.PointClamp, RasterizerState.Default, ScreenspaceWobble, null);
			batch.Draw(rendBuffer, winBuff, new Rectangle(0, 0, rendBuffer.Width, rendBuffer.Height), 0, Vector2.Zero, Color.White);
		batch.End();
			
	}

}
