//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Fabio on 04/02/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Gameplay.h"

@implementation Gameplay {
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
}

- (void)didLoadFromCCB {
    self.userInteractionEnabled = TRUE;
}

- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event{
    [self launchPenguin];
}

- (void)launchPenguin {
    //load the penguin.ccb
    CCNode *penguin = [CCBReader load:@"Penguin"];
    penguin.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    
    //add penguin to the physics node
    [_physicsNode addChild:penguin];
    
    //manually create and apply a force
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
}

@end
