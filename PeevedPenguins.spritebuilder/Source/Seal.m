//
//  Seal.m
//  PeevedPenguins
//
//  Created by Fabio on 03/02/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Seal.h"

@implementation Seal

- (id)init {
    self = [super init];
    
    if (self) {
        //CCLOG(@"Seal Created");
    }
    
    return self;
}

- (void)didLoadFromCCB {
    self.physicsBody.collisionType = @"seal";
}

@end
