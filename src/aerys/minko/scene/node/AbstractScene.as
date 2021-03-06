package aerys.minko.scene.node
{
	import aerys.minko.scene.SceneIterator;
	import aerys.minko.scene.action.IAction;

	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;

	public class AbstractScene extends EventDispatcher implements IScene
	{
		private static var _id	: uint			= 0;

		private var _name		: String			= null;
		private var _parents	: SceneIterator		= new SceneIterator();
		private var _actions	: Vector.<IAction>	= new Vector.<IAction>();

		public function get name() 		: String			{ return _name; }
		public function get parents()	: SceneIterator		{ return _parents; }
		public function get actions()	: Vector.<IAction>	{ return _actions; }

		public function set name(value : String) : void
		{
			_name = value;
		}

		public function AbstractScene()
		{
			_name = getDefaultSceneName(this);
		}

		public static function getDefaultSceneName(scene : IScene) : String
		{
			var className : String = getQualifiedClassName(scene);

			return className.substr(className.lastIndexOf(":") + 1)
				   + "_" + (++_id);
		}

		public function reparent(replacement : IScene) : void
		{
			var numParents : int = 0;

			for (var i : int = 0; i < numParents; ++i)
			{

			}
		}
	}
}