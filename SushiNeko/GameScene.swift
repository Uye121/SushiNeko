//
//  GameScene.swift
//  SushiNeko
//
//  Created by Ulric Ye on 6/27/16.
//  Copyright (c) 2016 TestingDummies@_@. All rights reserved.
//

import SpriteKit

/* Tracking enum for use with character and sushi side */
enum Side {
    case Left, Right, None
}

enum GameState {
    case Title, Ready, Playing, GameOver
}

class GameScene: SKScene {
    /* Game objects */
    var sushiBasePiece: SushiPiece!
    var character: Character!
    /* Sushi tower array */
    var sushiTower: [SushiPiece] = []
    var state: GameState = .Title
    var playButton: MSButtonNode!
    
    var scoreLabel: SKLabelNode!
    var healthBar: SKSpriteNode!
    var screen: SKSpriteNode!
    var time: Int = 0
    
    var path = NSBundle.mainBundle().pathForResource("IntroEffects", ofType: "sks")
    
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = String(score)
        }
    }
    var health: CGFloat = 1.0 {
        didSet {
            /* Scale health bar between 0.0 -> 1.0 e.g 0 -> 100% */
            healthBar.xScale = health
        }
    }
    
    override func didMoveToView(view: SKView) {
        sushiBasePiece = childNodeWithName("sushiBasePiece") as! SushiPiece
        character = childNodeWithName("character") as! Character
        playButton = childNodeWithName("playButton") as! MSButtonNode
        healthBar = childNodeWithName("healthBar") as! SKSpriteNode
        scoreLabel = childNodeWithName("scoreLabel") as! SKLabelNode
        screen = childNodeWithName("screen") as! SKSpriteNode
        //node = childNodeWithName("Effects")! as SKNode
        
        sushiBasePiece.connectChopsticks()
        /* Manually stack the start of the tower */
        addTowerPiece(.None)
        addTowerPiece(.Right)
        addRandomPieces(10)
        
        var specialEffect = NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as! SKEmitterNode

        /* Add in special effect */
        if state != .Playing {
            specialEffect.position = CGPointMake(self.size.width, self.size.height)
            specialEffect.name = "specialEffect"
            specialEffect.targetNode = self.scene
            
            self.addChild(specialEffect)
        }
        
        playButton.selectedHandler = {
            self.state = .Ready
            /* move the screen up */
            self.screen.runAction(SKAction.moveBy(CGVector(dx: 0, dy: 710), duration: 1.0))
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Game is not ready to play */
        if state == .GameOver || state == .Title { return }
        /* Game begins on the first touch */
        
        if state == .Ready {
            state = .Playing
        }
        
        /* Called when a touch begins */
        
        for touch in touches {
            /* Get touch position in scene */
            let location = touch.locationInNode(self)
            
            /* Was touch on left/right hand side of screen? */
            if location.x > size.width / 2 {
                character.side = .Right
            } else {
                character.side = .Left
            }
            /* Grab sushi piece on top of the base sushi piece, it will always be 'first' */
            let firstPiece = sushiTower.first as SushiPiece!
            
            /* Check collision */
            if character.side == firstPiece.side {
                for node: SushiPiece in sushiTower {
                    node.runAction(SKAction.moveBy(CGVector(dx: 0, dy: -55), duration: 0.10))
                }
                
                gameOver()
                
                return
            }
            /* increment health */
            health += 0.1
            /* increment score */
            score += 1
            
            
            /* Remove from sushi tower array */
            sushiTower.removeFirst()
            firstPiece.flip(character.side)
            
            /* Add a new sushi piece to the top of the sushi tower */
            addRandomPieces(1)
            
            /* Drop all the sushi pieces down one place */
            for node:SushiPiece in sushiTower {
                node.runAction(SKAction.moveBy(CGVector(dx: 0, dy: -55), duration: 0.10))
                
                /* Reduce zPosition to stop zPosition climbing over UI */
                node.zPosition -= 1
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if state != .Playing { return }
        
        /* Decrease Health */
        health -= 0.01
        
        if health >= 1 { health = 1 }
        
        /* Player out of health? */
        if health < 0 { gameOver() }
    }
    
    func addTowerPiece(side: Side) {
        /* Add a new sushi piece to the sushi tower */
        
        /* Copy original sushi piece */
        let newPiece = sushiBasePiece.copy() as! SushiPiece
        newPiece.connectChopsticks()
        
        /* Access last piece properties */
        let lastPiece = sushiTower.last
        
        /* Add on top of last piece, default on first piece */
        let lastPosition = lastPiece?.position ?? sushiBasePiece.position
        newPiece.position = lastPosition + CGPoint(x: 0, y: 55)
        
        /* Increment Z to ensure it's on top of the last piece, default on first piece*/
        let lastZPosition = lastPiece?.zPosition ?? sushiBasePiece.zPosition
        newPiece.zPosition = lastZPosition + 1
        
        /* Set side */
        newPiece.side = side
        
        /* Add sushi to scene */
        addChild(newPiece)
        
        /* Add sushi piece to the sushi tower */
        sushiTower.append(newPiece)
    }
    
    func addRandomPieces(total: Int) {
        /* Add random sushi pieces to the sushi tower */
        
        for _ in 1...total {
            
            /* Need to access last piece properties */
            let lastPiece = sushiTower.last as SushiPiece!
            
            /* Need to ensure we don't create impossible sushi structures */
            if lastPiece.side != .None {
                addTowerPiece(.None)
            } else {
                
                /* Random Number Generator */
                let rand = CGFloat.random(min: 0, max: 1.0)
                
                if rand < 0.45 {
                    /* 45% Chance of a left piece */
                    addTowerPiece(.Left)
                } else if rand < 0.9 {
                    /* 45% Chance of a right piece */
                    addTowerPiece(.Right)
                } else {
                    /* 10% Chance of an empty piece */
                    addTowerPiece(.None)
                }
            }
        }
    }
    
    func gameOver() {
        /* Game over! */
        
        state = .GameOver
        
        /* Turn all the sushi pieces red*/
        for node:SushiPiece in sushiTower {
            node.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        }
        
        /* Make the player turn red */
        character.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        
        /* Change play button selection handler */
        playButton.selectedHandler = {
            
            /* Grab reference to the SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Restart GameScene */
            skView.presentScene(scene)
            
            
        }
    }
}
