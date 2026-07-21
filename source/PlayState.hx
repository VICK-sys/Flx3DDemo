package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import openfl.utils.Assets;

class PlayState extends FlxState
{
	var cube:ModelSprite;
	var ico:ModelSprite;
	var status:FlxText;

	override public function create()
	{
		super.create();
		ModelCache.enableAutoClear();

		cube = new ModelSprite(40, 120, 260, 260, "assets/models/cube.obj", Assets.getBitmapData("assets/images/crate.png"));
		cube.spinX = 0.4;
		add(cube);

		ico = new ModelSprite(340, 120, 260, 260, "assets/models/ico.obj");
		ico.baseColor = 0xCC66DD;
		ico.spinX = -0.3;
		ico.spinY = 0.7;
		add(ico);

		status = new FlxText(0, 8, FlxG.width, "", 12);
		status.alignment = CENTER;
		add(status);

		var help = new FlxText(0, 448, FlxG.width, "SPACE toggle spin | ARROWS rotate | S toggle vertex snap", 12);
		help.alignment = CENTER;
		add(help);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			var spinning = cube.spinY != 0;
			cube.spinY = spinning ? 0 : 0.9;
			cube.spinX = spinning ? 0 : 0.4;
			ico.spinY = spinning ? 0 : 0.7;
			ico.spinX = spinning ? 0 : -0.3;
		}

		if (FlxG.keys.pressed.LEFT)
			rotateBoth(-1.5 * elapsed, 0);
		if (FlxG.keys.pressed.RIGHT)
			rotateBoth(1.5 * elapsed, 0);
		if (FlxG.keys.pressed.UP)
			rotateBoth(0, -1.5 * elapsed);
		if (FlxG.keys.pressed.DOWN)
			rotateBoth(0, 1.5 * elapsed);

		if (FlxG.keys.justPressed.S)
		{
			cube.vertexSnap = !cube.vertexSnap;
			ico.vertexSnap = cube.vertexSnap;
		}

		status.text = "software 3D | snap: " + (cube.vertexSnap ? "on" : "off");
	}

	function rotateBoth(dy:Float, dx:Float)
	{
		cube.rotY += dy;
		cube.rotX += dx;
		ico.rotY += dy;
		ico.rotX += dx;
	}
}
