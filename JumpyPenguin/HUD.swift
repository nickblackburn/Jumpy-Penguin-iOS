//
//  HUD.swift
//  JumpyPenguin
//
//  Created by Nicholas Blackburn on 5/24/16.
//  Copyright © 2016 Nicholas Blackburn. All rights reserved.
//

import SpriteKit

class HUD: SKNode {
    var textureAtlas:SKTextureAtlas = SKTextureAtlas(named:"hud.atlas")
    var heartNodes:[SKSpriteNode] = []
    let coinCountText = SKLabelNode(text: "0")
    let highScoreText = SKLabelNode(text: "0")
    var restartButton = SKSpriteNode()
    var menuButton = SKSpriteNode()
    let menuButton1 = SKSpriteNode()
    let pauseButton = SKSpriteNode()
    let playButton = SKSpriteNode()
    
    func createHudNodes(_ screenSize:CGSize) {
        // --- Create the coin counter ---
        // First, create an position a bronze coin icon for the coin counter:
        let coinTextureAtlas:SKTextureAtlas = SKTextureAtlas(named:"goods.atlas")
        let coinIcon = SKSpriteNode(texture: coinTextureAtlas.textureNamed("coin-bronze.png"))
        let highScoreTextureAtlas:SKTextureAtlas = SKTextureAtlas(named:"goods.atlas")
        let highScoreIcon = SKSpriteNode(texture: highScoreTextureAtlas.textureNamed("coin-gold.png"))
        // Size and position the coin icon:
        let coinYPos = screenSize.height - 20
        coinIcon.size = CGSize(width: 26, height: 26)
        coinIcon.position = CGPoint(x: 23, y: coinYPos)
        let highScoreYPos = screenSize.height - 50
        highScoreIcon.size = CGSize(width: 26, height: 26)
        highScoreIcon.position = CGPoint(x:23, y: highScoreYPos)
        
        // Configure the coin text label:
        coinCountText.fontName = "AvenirNext-HeavyItalic"
        coinCountText.position = CGPoint(x: 41, y: coinYPos)
        highScoreText.fontName = "AvenirNext-HeavyItalic"
        highScoreText.position = CGPoint(x: 41, y: highScoreYPos)
        // These two properties allow you to align the text relative to the SKLabelNode's position:
        coinCountText.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        coinCountText.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        highScoreText.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        highScoreText.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        // Add the text label and coin icon to the HUD:
        self.addChild(coinCountText)
        self.addChild(coinIcon)
        self.addChild(highScoreText)
        self.addChild(highScoreIcon)
        
        // Create three heart nodes for the life meter:
        // TEST TES TEST
        let range = [0,1,2]
        for index in range {
            let newHeartNode = SKSpriteNode(texture: textureAtlas.textureNamed("heart-full.png"))
            newHeartNode.size = CGSize(width: 46, height: 40)
            // Position the heart nodes in a row, just below the coin counter:
            let xPos = CGFloat(index * 60 + 33)
            let yPos = screenSize.height - 90
            newHeartNode.position = CGPoint(x: xPos, y: yPos)
            // Keep track of the nodes in an array property on HUD:
            heartNodes.append(newHeartNode)
            // Add the heart nodes to the HUD:
            self.addChild(newHeartNode)
        }
        
        // Add the restart and menu button textures to the nodes:
        restartButton.texture = textureAtlas.textureNamed("restartButton.png")
        menuButton.texture = textureAtlas.textureNamed("menuButton.png")
        // Assign node names to the buttons:
        restartButton.name = "restartGame"
        menuButton.name = "returnToMenu"
        // Position the button node:
        let centerOfHud = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        restartButton.position = centerOfHud
        menuButton.position = CGPoint(x: centerOfHud.x - 140, y: centerOfHud.y)
        // Size the button nodes:
        restartButton.size = CGSize(width: 140, height: 140)
        menuButton.size = CGSize(width: 70, height: 70)
        
        topRightDisplay(screenSize)
    }
    
    func showButtons() {
        // Set the button alpha to 0:
        restartButton.alpha = 0
        menuButton.alpha = 0
        // Add the button nodes to the HUD:
        self.addChild(restartButton)
        self.addChild(menuButton)
        // Fade in the buttons:
        let fadeAnimation = SKAction.fadeAlpha(to: 1, duration: 0.4)
        restartButton.run(fadeAnimation)
        menuButton.run(fadeAnimation)
    }
    
    func showButtons1() {
        menuButton1.alpha = 0
        pauseButton.alpha = 1
        playButton.alpha = 0
        self.addChild(menuButton1)
        self.addChild(pauseButton)
        self.addChild(playButton)
    }
    
    func topRightDisplay(_ screenSize:CGSize) {
        menuButton1.texture = textureAtlas.textureNamed("button-menu1.png")
        pauseButton.texture = textureAtlas.textureNamed("pause-button.png")
        playButton.texture = textureAtlas.textureNamed("play-button.png")
        menuButton1.name = "menuButton1"
        pauseButton.name = "pauseButton"
        playButton.name = "playButton"
        let topRightHud = CGPoint(x: screenSize.width - 60, y: screenSize.height - 35)
        playButton.position = topRightHud
        pauseButton.position = topRightHud
        menuButton1.position = CGPoint(x: screenSize.width - 125, y: screenSize.height - 35)
        playButton.size = CGSize(width: 50, height: 50)
        pauseButton.size = CGSize(width: 50, height: 50)
        menuButton1.size = CGSize(width: 50, height: 50)
        
        showButtons1()
    }
    
    func setCoinCountDisplay(_ newCoinCount:Int) {
        // We can use the NSNumberFormatter class to pad leading 0's onto the coin count:
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        if let coinStr = formatter.string(from: NSNumber(value: newCoinCount)) {
            // Update the label node with the new coin count:
            coinCountText.text = coinStr
        }
    }
    
    func setHighScoreDisplay() {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1

        highScoreText.text = "\(MyVariables.HIGH_SCORE)"
        
    }
    
    func setHealthDisplay(_ newHealth:Int) {
        // Create a fade SKAction to fade out any lost hearts:
        let fadeAction = SKAction.fadeAlpha(to: 0.2, duration: 0.3)
        // Loop through each heart and update its status:
        let range = 0..<heartNodes.count
        for index in range {
            if index < newHealth {
                // This heart should be full red:
                heartNodes[index].alpha = 1
            }
            else {
                // This heart should be faded:
                heartNodes[index].run(fadeAction)
            }
        }
    }
    
    func addHealthLife(_ screenSize:CGSize) {
        
        if (MyVariables.HEALTH < 3) {
            // Create as many heart nodes as needed for the life meter:
            let range = 0..<MyVariables.HEALTH
            for index in range {
                let newHeartNode = SKSpriteNode(texture: textureAtlas.textureNamed("heart-full.png"))
                newHeartNode.size = CGSize(width: 46, height: 40)
                // Position the heart nodes in a row, just below the coin counter:
                let xPos = CGFloat(index * 60 + 33)
                let yPos = screenSize.height - 90
                newHeartNode.position = CGPoint(x: xPos, y: yPos)
                // Keep track of the nodes in an array property on HUD:
                heartNodes.append(newHeartNode)
                // Add the heart nodes to the HUD:
                self.addChild(newHeartNode)
            }
        }
    }
}
