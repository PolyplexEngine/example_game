module example_game.world;
import example_game.player;
import example_game.enemy;
import example_game.block;
import example_game.app;
import polyplex.core.game;
import polyplex.core.render;
import polyplex.core.content;
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

	public Block[] Blocks;
	public Enemy[] Enemies;
	public Player GamePlayer;

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
		CameraX = (MyGame.GameDrawing.Window.Width/2)/CameraZoom;
		GamePlayer.ResetState();
		foreach(Block b; Blocks) {
			b.ResetState();
		}
		foreach(Enemy e; Enemies) {
			e.ResetState();
		}
	}

	public void Init(ContentManager man) {
		Block.Reset();
		GamePlayer.Init(man.LoadTexture("player.png"));
		Block.Init(man.LoadTexture("tiles.png"), GamePlayer);
		Enemy.Init(man.LoadTexture("enemy_a.png"));
		ResetStage();
	}

	public void Update(GameTimes times) {
		foreach(Block b; Blocks) {
			if (b is null) continue;
			b.Update(times);
		}
		GamePlayer.Update(times);
		this.camera.Origin = Vector2(MyGame.GameDrawing.Window.Width/2, MyGame.GameDrawing.Window.Height);
		this.camera.Zoom = CameraZoom;
		if (GamePlayer.Position.X > CameraX) {
			CameraX = GamePlayer.Position.X;
		}

		// Do funky camera buissness
		MyGame.GameDrawing.Window.Position = Vector2(CameraX, CameraY);

		CameraY = GamePlayer.Position.Y+128;
		if (CameraY > (world_height*16)) CameraY = (world_height*16);
		if (CameraX -(MyGame.GameDrawing.Window.Width/2)/CameraZoom < 0) CameraX = (MyGame.GameDrawing.Window.Width/2)/CameraZoom;
		this.camera.Position = Vector2(CameraX, CameraY);

		foreach(Enemy e; Enemies) {
			if (e is null) continue;
			e.Update(times);
		}
	}

	public void Draw(GameTimes times, SpriteBatch batch) {
		batch.Begin(SpriteSorting.Deferred, Blending.NonPremultiplied, Sampling.PointClamp, null, camera);
		foreach(Block b; Blocks) {
			if (b is null) continue;
			b.Draw(times, batch);
		}
		GamePlayer.Draw(times, batch);

		foreach(Enemy e; Enemies) {
			if (e is null) continue;
			e.Draw(times, batch);
		}
		batch.End();
	}

}
