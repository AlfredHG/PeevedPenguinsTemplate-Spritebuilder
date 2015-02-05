//
//  WaitingPenguin.m
//  PeevedPenguins
//
//  Created by Fabio on 05/02/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "WaitingPenguin.h"

@implementation WaitingPenguin

- (void) didLoadFromCCB {
    //generate a random number between 0.0 and 2
    float delay = (arc4random() % 2000) / 1000.f;
    //call method to start animation after random delay
    [self performSelector:@selector(startBlinkAndJump) withObject:nil afterDelay:delay];
}

- (void) startBlinkAndJump {
    // the animation manager of each node is stored in the 'animationManager' property
    CCAnimationManager * animationManager = self.animationManager;
    // timelines can bereferenced and run by name
    [animationManager runAnimationsForSequenceNamed:@"BlinkAndJump"];
}

@end
