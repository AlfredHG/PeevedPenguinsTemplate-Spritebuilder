//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Fabio on 04/02/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_catapultArm;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    
    //penguin
    CCNode *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
}

// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // visualize physics bodies & joints
    //_physicsNode.debugDraw = TRUE;
    _physicsNode.collisionDelegate = self;
        
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
    // load level
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    
    // nothing shall collide with our invisible nodes
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
}

// called on every touch in this scene
-(void) touchBegan:(CCTouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    // start catapult dragging when a touch inside of the catapult arm occurs
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation)) {
        // move the mouseJointNode to the touch position
        _mouseJointNode.position = touchLocation;
        
        
        // setup a spring joint between the mouseJointNode and the catapultArm
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
        
        //create a penguin
        _currentPenguin = [CCBReader load: @"Penguin"];
        // posiziona sul braccio
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        // transform world position to node space
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        // add to the physics world
        [_physicsNode addChild: _currentPenguin];
        // no rotation
        _currentPenguin.physicsBody.allowsRotation = NO;
        
        // creo un joint per tener fermo il pinguino
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
    }
}
- (void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event{
    //quando il touch si muove update position of the mouseJointnode to the touch pos
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    [self releaseCatapult];
}

- (void)touchCancelled:(CCTouch *)touch withEvent:(CCTouchEvent *)event{
    [self releaseCatapult];
}

- (void)releaseCatapult {
    if (_mouseJoint != nil) {
        // releases the jount and lets the catapult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        
        // dopo il lancio ok rotation
        _currentPenguin.physicsBody.allowsRotation = YES;
        
        // follow the flying peng
        CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:follow];
    }
}

- (void)launchPenguin {
    // loads the Penguin.ccb we have set up in Spritebuilder
    CCNode* penguin = [CCBReader load:@"Penguin"];
    // position the penguin at the bowl of the catapult
    penguin.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    
    // add the penguin to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:penguin];
    
    // manually create & apply a force to launch the penguin
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
    
    // follow penguin
    self.position = ccp(0,0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];
}

- (void)retry {
    [[CCDirector sharedDirector] replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}

// collisions

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB {
    //CCLOG(@"Something collided with a seal!");
    
    float energy = [pair totalKineticEnergy];
    // if energy is large enought, remove the seal
    if (energy > 5000.f){
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        }key:nodeA];
    }
}

- (void)sealRemoved: (CCNode *)seal {
    //load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    explosion.autoRemoveOnFinish = TRUE;
    explosion.position = seal.position;
    [seal.parent addChild:explosion];

    
    [seal removeFromParent];
}




@end
