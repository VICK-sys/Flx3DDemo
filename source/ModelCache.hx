package;

import ObjLoader.Model;
import flixel.FlxG;
import flixel.util.FlxSignal;

class ModelCache
{
	public static var onCleared(default, null):FlxSignal = new FlxSignal();

	static var models:Map<String, Model> = [];
	static var autoClearEnabled:Bool = false;

	public static function get(path:String):Null<Model>
	{
		if (models.exists(path))
			return models.get(path);

		var model:Model = null;
		try
		{
			model = ObjLoader.load(path);
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('ModelCache: failed to load "$path": $e');
			trace('ModelCache: failed to load "$path": $e');
		}

		if (model != null)
			models.set(path, model);
		return model;
	}

	public static function enableAutoClear():Void
	{
		if (autoClearEnabled)
			return;
		autoClearEnabled = true;
		FlxG.signals.preStateSwitch.add(clear);
	}

	public static function clear():Void
	{
		models.clear();
		onCleared.dispatch();
	}
}
