//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Fabio on 04/02/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Penguin.h"

static const float MIN_SPEED = 5.f;

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_catapultArm;
    CCNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    
    //penguin
    Penguin *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
    CCAction *_followPenguin;
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

// method called every frame
- (void) update:(CCTime)delta {
    if (_currentPenguin.launched) {
        //if speed is below minimum speed assume attempt is over
        // questa espressione calcola la lunghezza del vettore!!!!!!
        if (ccpLength(_currentPenguin.physicsBody.velocity) < MIN_SPEED) {
            [self nextAttempt];
            return;
        }
        
        int xMin = _currentPenguin.boundingBox.origin.x;
        
        if (xMin < self.boundingBox.origin.x) {
            [self nextAttempt];
            return;
        }
        
        int xMax = xMin + _currentPenguin.boundingBox.size.width;
        
        if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width)){
            [self nextAttempt];
            return;
        }
    }
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
        _currentPenguin = (Penguin*)[CCBReader load: @"Penguin"];
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
        _followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguin];
        
        _currentPenguin.launched = YES;
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

- (void)nextAttempt {
    _currentPenguin = nil;
    [_contentNode stopAction:_followPenguin];
    
    CCActionMoveTo *actionMoveTo = [CCActionMoveTo actionWithDuration:1 position:ccp(0, 0)];
    [_contentNode runAction:actionMoveTo];
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
