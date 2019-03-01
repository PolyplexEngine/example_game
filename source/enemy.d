module example_game.enemy;
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

public class Enemy {
	public Vector2 Position;
	public Rectangle Hitbox;
	public Rectangle Drawbox;

	private static Texture2D Texture;
	private float gravity = 0.4f;
	private float gravity_add = 0f;

	private Vector2 start_position;

	private bool dead = false;

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
		this.start_position = pos;
		this.Hitbox = new Rectangle(cast(int)pos.X+4, cast(int)pos.Y, 8, 16);
		this.parent = parent;
		
		int tm = 10;

		animations = [
			"idle": [
				new AnimationData(0, 0, tm)
			],
			"introwalk": [
				new AnimationData(0, 1, tm),
				new AnimationData(1, 1, tm),
				new AnimationData(2, 1, tm),
				new AnimationData(3, 1, tm),
				new AnimationData(4, 1, tm),
				new AnimationData(5, 1, tm),
				new AnimationData(6, 1, tm),
				new AnimationData(7, 1, tm),
			],
			"walk": [
				new AnimationData(0, 1, tm-5),
				new AnimationData(1, 1, tm-5),
				new AnimationData(2, 1, tm-5),
				new AnimationData(3, 1, tm-5),
				new AnimationData(4, 1, tm-5),
				new AnimationData(5, 1, tm-5),
				new AnimationData(6, 1, tm-5),
				new AnimationData(7, 1, tm-5),
			],
			"run": [
				new AnimationData(0, 1, tm/4),
				new AnimationData(1, 1, tm/4),
				new AnimationData(2, 1, tm/4),
				new AnimationData(3, 1, tm/4),
				new AnimationData(4, 1, tm/4),
				new AnimationData(5, 1, tm/4),
				new AnimationData(6, 1, tm/4),
				new AnimationData(7, 1, tm/4),
			],
			"dead": [
				new AnimationData(0, 2, tm),
			],
			"sit": [
				new AnimationData(0, 2, tm),
			],
			"shimmy": [
				new AnimationData(0, 2, tm),
				new AnimationData(0, 1, tm/2),
			],
			"jump": [
				new AnimationData(1, 2, tm),
			],
		];
		this.Drawbox = new Rectangle(cast(int)Position.X, cast(int)Position.Y, 16, 16);
	}

	public void Kill() {
		dead = true;
		ChangeAnimation("dead");
	}

	public void ResetState() {
		this.momentum_x = 0;
		this.momentum_y = 0;
		this.jumps = 2;
		this.Position = this.start_position;
		this.dead = false;
		flip = SpriteFlip.None;
		ChangeAnimation("idle");
	}

	public static void Init(Texture2D tex) {
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
		return animations[animation_name][frame%animations[animation_name].length].Animation;
	}

	public int GetAnimationTimeout() {
		return animations[animation_name][frame%animations[animation_name].length].Timeout;
	}

	private KeyboardState last_state_jmp;
	private KeyboardState current_state_jmp;
	private bool grounded = false;

	private bool walk_direction = false;

	public void Update(GameTimes times) {
		if (dead) return;

		// MOVE.
		running = false;
		speed = 2f;
		drag = 2f;
		
		if (walk_direction) {
			flip = SpriteFlip.None;
			momentum_x += speed;
			if (jumps > 0 && grounded) {
				if (Keyboard.GetState().IsKeyDown(Keys.Down)) ChangeAnimation("shimmy");
				else if (running) ChangeAnimation("run");
				else ChangeAnimation("walk");
			}
		} else if (!walk_direction) {
			flip = SpriteFlip.FlipVertical;
			momentum_x -= speed;
			if (jumps > 0 && grounded) {
				if (Keyboard.GetState().IsKeyDown(Keys.Down)) ChangeAnimation("shimmy");
				else if (running) ChangeAnimation("run");
				else ChangeAnimation("walk");
			}
		}

		

		// COLLIDE Y (& BORDER).

		if (this.Position.X+32 + momentum_x < -32) {
			//this.Position.X = parent.CameraX - ((MyGame.GameDrawing.Window.Width/2)/parent.CameraZoom)-1;
			Kill();
		}


		if (this.parent.GamePlayer.Hitbox.Intersects(this.Drawbox)) {
			if (this.parent.GamePlayer.Momentum.Y > 1) Kill();
			else parent.GamePlayer.Kill();
			return;
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
				this.walk_direction = true;
				if (this.momentum_x > 0f) {
					this.walk_direction = false;
				}
				this.momentum_x = 0f;
			}
		}
		
		handle_gravity();
		
		cap_momentum();

		apply_momentum();

		update_anim();

		last_state_jmp = current_state_jmp;
		if (this.Position.Y > this.parent.WorldBounds.Height) {
			Kill();
		}
	}

	private void handle_gravity() {
		momentum_y += gravity+gravity_add;

		gravity_add += 0.1f;
		if (gravity_add > 0.4f) gravity_add = 0.4f;
	}

	private void handle_jump() {
		current_state_jmp = Keyboard.GetState();
		if (current_state_jmp.IsKeyDown(Keys.Up)) {
			jump_timer = 0;
		}
		if (current_state_jmp.IsKeyDown(Keys.Up) && last_state_jmp.IsKeyUp(Keys.Up)) {
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
			if (jump_timer == jump_timeout-1) {
				momentum_y = -2f;
			}
			momentum_y -= jump_speed;
			jump_timer--;
		}
	}

	private void cap_momentum() {
		momentum_x /= drag;
		momentum_y /= jump_drag;

		if (momentum_x > momentum_x_cap) momentum_x = momentum_x_cap;
		if (momentum_y > momentum_y_cap) momentum_y = momentum_y_cap;
		if (momentum_x < -momentum_x_cap) momentum_x = -momentum_x_cap;
		if (momentum_y < -momentum_y_cap) momentum_y = -momentum_y_cap;
	}

	private void apply_momentum() {
		//APPLY.
		this.Position += Vector2(momentum_x, momentum_y);
		this.Hitbox = new Rectangle(cast(int)Position.X+4, cast(int)Position.Y, 8, 16);
		this.Drawbox = new Rectangle(cast(int)Position.X, cast(int)Position.Y, 16, 16);
	}

	private void update_anim() {
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