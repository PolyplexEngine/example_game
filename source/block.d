module example_game.block;
import example_game.player;
import polyplex.core.content;
import polyplex.core.render;
import polyplex.core.color;
import polyplex.core.game;
import polyplex.math;
import polyplex.utils.logging;

public class Block {
	private static Texture2D texture;
	private static Player player;

	public int Id;
	public int IdY;
	public Rectangle Hitbox;
	
	private int start_id;
	private int start_idy;

	private Rectangle Drawbox;
	private int pos_y = 0;
	private int bonk_i = 0;
	private int bonk_i_max = 3;
	private int bonk_i_timer = 0;
	private int bonk_i_timer_b = 2;

	this(int id, Vector2 position) {
		this.Hitbox = new Rectangle(cast(int)position.X, cast(int)position.Y, 16, 16);
		this.Drawbox = new Rectangle(cast(int)position.X, cast(int)position.Y-bonk_i, 16, 16);
		pos_y = cast(int)position.Y;
		this.Id = id%4;
		this.IdY = cast(int)id/4;

		this.start_id = this.Id;
		this.start_idy = this.IdY;
	}

	public void ResetState() {
		this.Id = this.start_id;
		this.IdY = this.start_idy;
	}

	public static void Reset() {
		this.player = null;
	}

	public static void Init(Texture2D tex, Player pl) {
		if (texture is null) this.texture = tex;
		if (player is null) this.player = pl;
	}

	public void Bonk() {
		if (bonk_i < bonk_i_max) {
			bonk_i = bonk_i_max;
		}
		if (Id == 0 && IdY == 1) {
			Id = 1;
		}
	}

	public void Update(GameTime times) {
		if (bonk_i_timer <= 0){
			bonk_i--;
			if (bonk_i < 0) bonk_i = 0;
			bonk_i_timer = bonk_i_timer_b;
		}
		bonk_i_timer--;
		this.Drawbox.Y = pos_y-bonk_i;
	}

	public void Draw(GameTime times, SpriteBatch batch) {
		batch.Draw(texture, Drawbox, new Rectangle(Id*16, IdY*16, 16, 16), Color.White, SpriteFlip.None, 0f);
	}
}