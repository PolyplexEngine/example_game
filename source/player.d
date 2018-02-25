module example_game.player;
import example_game.world;
import example_game.app;
import example_game.block;

import polyplex.core.content;
import polyplex.core.render;
import polyplex.core.color;
import polyplex.core.input;
import polyplex.core.game;
import polyplex.utils.logging;
import polyplex.math;

private class AnimationData {
	this(int frame, int animation, int timeout) {
		this.Frame = frame;
		this.Animation = animation;
		this.Timeout = timeout;
	}
	public int Frame;
	public int Animation;
	public int Timeout;
}

public class Player {
	public Vector2 Position;
	public Rectangle Hitbox;
	public Rectangle Drawbox;

	private static Texture2D Texture;
	private float gravity = 0.4f;
	private float gravity_add = 0f;

	//Animation
	private AnimationData[][string] animations;

	private string animation_name = "jump";
	private int frame = 0;
	private int frame_timeout = 10;
	private int frame_counter = 0;


	//Movement
	private int jumps = 2;
	private int jump_timer = 0;
	private int jump_timeout = 14;

	private float momentum_x = 0f;
	private float momentum_y = 0f;
	private float momentum_x_cap = 5f;
	private float momentum_y_cap = 10f;

	private float speed = 1.5f;
	private float jump_speed = 1.6f;

	private bool running = false;

	private float drag = 2f;
	private float jump_drag = 1.2f;
	private World parent;

	//Animation
	private SpriteFlip flip = SpriteFlip.None;

	this(Vector2 pos, World parent) {
		this.Position = pos;
		this.Hitbox = new Rectangle(cast(int)pos.X+4, cast(int)pos.Y, 8, 16);
		this.parent = parent;
		
		int tm = 10;

		animations = [
			"idle": [
				new AnimationData(0, 0, tm)
			],
			"walk": [
				new AnimationData(0, 1, tm),
				new AnimationData(1, 1, tm),
				new AnimationData(2, 1, tm),
				new AnimationData(3, 1, tm),
				new AnimationData(4, 1, tm),
				new AnimationData(5, 1, tm),
				new AnimationData(6, 1, tm),
				new AnimationData(7, 1, tm),
			],
			"sit": [
				new AnimationData(0, 2, tm),
			],
			"jump": [
				new AnimationData(1, 2, tm),
			],
			"dead": [
				new AnimationData(0, 3, tm),
			],
			"victory": [
				new AnimationData(0, 4, tm),
			]
		];
	}

	public void Init(Texture2D tex) {
		if (Texture is null) Texture = tex;
	}

	public void ChangeAnimation(string name) {
		if (animation_name == name) return;
		this.animation_name = name;
		this.frame = animations[animation_name][0].Frame;
	}

	public int GetAnimationX() {
		return animations[animation_name][frame%animations[animation_name].length].Frame;
	}

	public int GetAnimationY() {
		return animations[animation_name][0].Animation;
	}

	public int GetAnimationTimeout() {
		return animations[animation_name][frame%animations[animation_name].length].Timeout;
	}

	private KeyState last_state_jmp;
	private KeyState current_state_jmp;
	private bool grounded = false;
	public void Update(GameTimes times) {

		// MOVE.
		running = false;
		speed = 2f;
		drag = 2f;

		if (Input.IsKeyDown(KeyCode.KeyZ)) {
			running = true;
			speed = 4f;
			drag = 2f;
		}
		
		if (Input.IsKeyDown(KeyCode.KeyD) || Input.IsKeyDown(KeyCode.KeyRight)) {
			flip = SpriteFlip.None;
			momentum_x += speed;
			if (jumps > 0 && grounded) ChangeAnimation("walk");
		} else if (Input.IsKeyDown(KeyCode.KeyA) || Input.IsKeyDown(KeyCode.KeyLeft)) {
			flip = SpriteFlip.FlipVertical;
			momentum_x -= speed;
			if (jumps > 0 && grounded) ChangeAnimation("walk");
		} else if (Input.IsKeyDown(KeyCode.KeyDown)) {
			ChangeAnimation("sit");	
		} else {
			if (jumps > 0 && grounded) ChangeAnimation("idle");
		}

		

		// COLLIDE Y (& BORDER).

		if (this.Position.X-1 + momentum_x < parent.CameraX - ((MyGame.GameDrawing.Window.Width/2)/parent.CameraZoom)) {
			this.Position.X = parent.CameraX - ((MyGame.GameDrawing.Window.Width/2)/parent.CameraZoom)-1;
			momentum_x = 0;
		}
		foreach(Block b; parent.Blocks) {
			if (b.Hitbox.Intersects(this.Hitbox.Displace(0, cast(int)this.momentum_y))) {
				if (this.Position.Y + 16 + momentum_y > b.Hitbox.Top) {
					if (this.Position.Y < b.Hitbox.Top) {
						grounded = true;
						jumps = 2;
						gravity_add = 0f;
						jump_timer = 0;
						this.momentum_y = 0f;
						this.Position.Y = b.Hitbox.Y-16;
					} else {
						this.momentum_y = 0.3f;
						this.Position.Y = b.Hitbox.Bottom+4;
						jumps = -1;
						jump_timer = 0;
						b.Bonk();
					}
				}
			}
		}

		// COLLIDE X.
		foreach(Block b; parent.Blocks) {
			if (b.Hitbox.Intersects(this.Hitbox.Displace(cast(int)this.momentum_x, -1))) {
				this.momentum_x = 0f;
			}
		}

		// JUMP.
		current_state_jmp = Input.GetState(KeyCode.KeyX);
		if (current_state_jmp == KeyState.Up) {
			jump_timer = 0;
		}
		if (current_state_jmp == KeyState.Down && last_state_jmp == KeyState.Up) {
			if (jumps > 0) {
				//if (jumps == 2 || jump_timer > 0) {
					jumps--;
					jump_timer = jump_timeout;
				//}
				grounded = false;
				ChangeAnimation("jump");
			}
		}

		if (jump_timer > 0) {
			momentum_y -= jump_speed;
			jump_timer--;
		}
		
		momentum_y += gravity+gravity_add;

		gravity_add += 0.1f;
		if (gravity_add > 0.4f) gravity_add = 0.4f;
		


		// CAP.
		momentum_x /= drag;
		momentum_y /= jump_drag;

		if (momentum_x > momentum_x_cap) momentum_x = momentum_x_cap;
		if (momentum_y > momentum_y_cap) momentum_y = momentum_y_cap;
		if (momentum_x < -momentum_x_cap) momentum_x = -momentum_x_cap;
		if (momentum_y < -momentum_y_cap) momentum_y = -momentum_y_cap;

		//APPLY.
		this.Position.X += momentum_x;
		this.Position.Y += momentum_y;
		this.Hitbox = new Rectangle(cast(int)Position.X+4, cast(int)Position.Y, 8, 16);
		this.Drawbox = new Rectangle(cast(int)Position.X, cast(int)Position.Y, 16, 16);
		last_state_jmp = current_state_jmp;
		frame_timeout = GetAnimationTimeout();
		if (frame_counter >= frame_timeout) {
			this.frame++;
			frame_counter = 0;
		}
		frame_counter++;
	}

	public void Draw(GameTimes times, SpriteBatch batch) {
		batch.Draw(Texture, this.Drawbox, new Rectangle(GetAnimationX()*16, GetAnimationY()*16, 16, 16), Color.White, flip);
	}
}