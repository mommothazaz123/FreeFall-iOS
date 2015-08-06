//
//  GameScene.m
//  FreeFall2
//
//  Created by Andrew Zhu on 8/6/15.
//  Copyright (c) 2015 Andrew Zhu. All rights reserved.
//

#import "GameScene.h"

@interface GameScene(){
    SKSpriteNode *_player;
    SKAction *_moveAndRemovePlatforms;
    SKNode *_moving;
    BOOL _canRestart;
    SKLabelNode *_distanceNode;
    NSUInteger _distance;
}

@end

@implementation GameScene

static const uint32_t playerCategory = 0x1 << 0;
static const uint32_t platformCategory = 0x1 << 1;
static const uint32_t worldCategory = 0x1 << 2;

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    self.backgroundColor = [UIColor blackColor];
    
    _moving = [SKNode node];
    [self addChild:_moving];
    
    _canRestart = NO;
    
    // player
    _player = [[SKSpriteNode alloc]initWithColor:[UIColor whiteColor] size:CGSizeMake(50, 50)];
    _player.position = CGPointMake(self.frame.size.width / 2, self.frame.size.height - _player.size.height * 2);
    
    _player.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_player.size];
    _player.physicsBody.dynamic = YES;
    _player.physicsBody.allowsRotation = NO;
    _player.physicsBody.categoryBitMask = playerCategory;
    _player.physicsBody.collisionBitMask = platformCategory | worldCategory;
    _player.physicsBody.contactTestBitMask = platformCategory | worldCategory;
    
    [self addChild:_player];
    
    // world
    self.physicsWorld.gravity = CGVectorMake(0, -9.81);
    self.physicsWorld.contactDelegate = self;
    
    SKNode* bottom = [SKNode node];
    bottom.position = CGPointMake(self.frame.size.width / 2, -1 * _player.size.height - 10);
    bottom.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width, 10)];
    bottom.physicsBody.dynamic = NO;
    bottom.physicsBody.categoryBitMask = worldCategory;
    [self addChild:bottom];
    
    SKNode* left = [SKNode node];
    left.position = CGPointMake(-10, self.frame.size.height / 2);
    left.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(10, self.frame.size.height)];
    left.physicsBody.dynamic = NO;
    left.physicsBody.categoryBitMask = worldCategory;
    [self addChild:left];
    
    SKNode* right = [SKNode node];
    right.position = CGPointMake(self.frame.size.width + 10, self.frame.size.height / 2);
    right.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(10, self.frame.size.height)];
    right.physicsBody.dynamic = NO;
    right.physicsBody.categoryBitMask = worldCategory;
    [self addChild:right];
    
    SKNode* top = [SKNode node];
    top.position = CGPointMake(self.frame.size.width / 2, self.frame.size.height + 5);
    top.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width, 10)];
    top.physicsBody.dynamic = NO;
    top.physicsBody.categoryBitMask = worldCategory;
    [self addChild:top];
    
    // platforms
    SKAction* movePlatforms = [SKAction moveByX:0 y:self.frame.size.height + 100 duration:0.01 * self.frame.size.height];
    SKAction* removePlatforms = [SKAction removeFromParent];
    SKAction* updateScore = [SKAction runBlock:^{
        if (_moving.speed > 0) {
            _distance++;
        }
    }];
    _moveAndRemovePlatforms = [SKAction sequence:@[movePlatforms, updateScore, removePlatforms]];
    
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(spawnPlatform) onTarget:self], [SKAction waitForDuration:1 withRange:1.5]]]]];
    
    // score
    _distance = 0;
    _distanceNode = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"Distance: %lu", (unsigned long)_distance]];
    _distanceNode.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    [self addChild:_distanceNode];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    if (_moving.speed > 0) {
        _player.physicsBody.velocity = CGVectorMake(_player.physicsBody.velocity.dx, 500);
    } else if (_canRestart) {
        [self restart];
    }
    
    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    _distanceNode.text = [NSString stringWithFormat:@"Distance: %lu", _distance];
}

-(void)didBeginContact:(SKPhysicsContact *)contact {
    /* Called when two objects make contact */
    NSLog(@"%@", @"Collision Detected");
    if (_moving.speed > 0) {
        _moving.speed = 0;
        
        _player.physicsBody.collisionBitMask = 0;
        _player.physicsBody.velocity = CGVectorMake(0, 500);
        
        [self removeActionForKey:@"flash"];
        [self runAction:[SKAction sequence:@[[SKAction runBlock:^{
            self.backgroundColor = [SKColor whiteColor];
        }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
            self.backgroundColor = [SKColor blackColor];
            _canRestart = YES;
        }]]] withKey:@"flash"];
    }
}

- (void)restart
{
    _player.position = CGPointMake(self.frame.size.width / 2, self.frame.size.height - _player.size.height * 2);
    _player.physicsBody.velocity = CGVectorMake(0, 0);
    _player.physicsBody.collisionBitMask = platformCategory | worldCategory;
    
    [_moving removeAllChildren];
    
    _canRestart = NO;
    
    _moving.speed = 1;
}

- (void)spawnPlatform
{
    int MAX_SIZE = self.frame.size.width / 5;
    int MIN_SIZE = self.frame.size.width / 25;
    CGFloat x = arc4random_uniform(self.frame.size.width - MIN_SIZE);
    CGFloat y = -50;
    CGFloat width = arc4random_uniform(MAX_SIZE - MIN_SIZE) + MIN_SIZE;
    SKSpriteNode* platform = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor] size:CGSizeMake(width, 25)];
    
    platform.position = CGPointMake(x, y);
    platform.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:platform.size];
    platform.physicsBody.dynamic = NO;
    platform.physicsBody.categoryBitMask = platformCategory;
    platform.physicsBody.contactTestBitMask = playerCategory;
    
    [platform runAction:_moveAndRemovePlatforms];
    
    [_moving addChild:platform];
}

@end
