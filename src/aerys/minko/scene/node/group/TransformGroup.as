﻿package aerys.minko.scene.node.group 
{
	import aerys.minko.scene.action.transform.PopTransformAction;
	import aerys.minko.scene.action.transform.PushTransformAction;
	import aerys.minko.scene.node.ITransformableScene;
	import aerys.minko.type.math.Transform3D;
	
	/**
	 * TransformGroup apply a 3D transform to their children.
	 * 
	 * @author Jean-Marc Le Roux
	 */
	public class TransformGroup extends Group implements ITransformableScene
	{
		private var _transform	: Transform3D		= new Transform3D();
			
		/**
		 * The Transform3D object defining the transform of the object into world-space.
		 */
		public function get transform() : Transform3D		{ return _transform; }
		
		public function TransformGroup(...children) 
		{
			super(children);
			
			actions.unshift(PushTransformAction.pushTransformAction);
			actions.push(PopTransformAction.popTransformAction);
		}
	}
}