package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.utils.Assets;

class PlayState extends FlxState
{
	var models:Array<ModelSprite> = [];
	var cube:ModelSprite;
	var marker:FlxSprite;
	var anchor:FlxPoint = FlxPoint.get();
	var status:FlxText;

	override public function create()
	{
		super.create();
		ModelCache.enableAutoClear();

		cube = new ModelSprite(50, 60, 200, 200, "assets/models/cube.obj", Assets.getBitmapData("assets/images/crate.png"));
		cube.spinX = 0.4;

		var ico = new ModelSprite(340, 60, 200, 200, "assets/models/ico.obj");
		ico.baseColor = 0xCC66DD;
		ico.spinX = -0.3;
		ico.spinY = 0.7;

		var sphere = new ModelSprite(50, 240, 200, 200);
		sphere.setModel(Primitives.sphere());
		sphere.baseColor = 0x44CCAA;
		sphere.spinX = 0.5;
		sphere.spinY = 0.6;

		var house = new ModelSprite(340, 240, 200, 200, "assets/models/house.obj");
		house.spinY = 0.6;
		house.camPitch = -0.35;

		models = [cube, ico, sphere, house];
		for (m in models)
		{
			m.modelScale = 0.8;
			add(m);
		}

		marker = new FlxSprite(0, 0);
		marker.makeGraphic(6, 6, FlxColor.RED);
		add(marker);

		status = new FlxText(0, 8, FlxG.width, "", 12);
		status.alignment = CENTER;
		add(status);

		var help = new FlxText(0, 448, FlxG.width, "SPACE spin | ARROWS rotate | S snap | W wireframe | F fog", 12);
		help.alignment = CENTER;
		add(help);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			var spinning = models[0].spinY != 0 || models[0].spinX != 0;
			for (m in models)
			{
				m.spinX = spinning ? 0 : m.spinX != 0 ? m.spinX : 0.4;
				m.spinY = spinning ? 0 : 0.7;
				if (spinning)
					m.spinX = 0;
			}
		}

		if (FlxG.keys.pressed.LEFT)
			for (m in models)
				m.rotY -= 1.5 * elapsed;
		if (FlxG.keys.pressed.RIGHT)
			for (m in models)
				m.rotY += 1.5 * elapsed;
		if (FlxG.keys.pressed.UP)
			for (m in models)
				m.rotX -= 1.5 * elapsed;
		if (FlxG.keys.pressed.DOWN)
			for (m in models)
				m.rotX += 1.5 * elapsed;

		if (FlxG.keys.justPressed.S)
			for (m in models)
				m.vertexSnap = !m.vertexSnap;
		if (FlxG.keys.justPressed.W)
			for (m in models)
				m.wireframe = !m.wireframe;
		if (FlxG.keys.justPressed.F)
			for (m in models)
				m.fogEnabled = !m.fogEnabled;

		cube.worldToScreen(1, 1, -1, anchor);
		marker.setPosition(cube.x + anchor.x - 3, cube.y + anchor.y - 3);

		status.text = "software 3D | snap: " + (models[0].vertexSnap ? "on" : "off")
			+ " | wire: " + (models[0].wireframe ? "on" : "off")
			+ " | fog: " + (models[0].fogEnabled ? "on" : "off");
	}
}
