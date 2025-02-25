//
//  GameViewModel.swift
//  ReversiAI
//
//  Created by Рома Николаев on 07.11.2024.
//

import SwiftUI

class GameViewModel: ObservableObject {
    enum GameMode {
        case playerVsPlayer, playerVsAI
    }
    
    @Published var board: [PieceOnBoard?] = Array(repeating: nil, count: 64)
    @Published var currentPlayer: Player = .black
    @Published var possibleMoves: Set<Int> = []
    @Published var blackCount = 2
    @Published var whiteCount = 2
    @Published var winner: String? = nil
    @Published var gameOver = false
    @Published var message = ""
    @Published var gameMode: GameMode = .playerVsPlayer
    
    private let directions = [-8, 8, -1, 1, -9, -7, 7, 9]
    
    enum Player {
        case black, white
    }
    
    struct PieceOnBoard {
        let player: Player
    }
    
    init() {
        resetGame()
    }
    
    func alert() -> String {
        var message: String = ""
        if gameOver {
            if winner == "black" {
                message = "Черные выиграли"
            } else if winner == "white" {
                message = "Белые выиграли"
            } else {
                message = "Ничья"
            }
        } else {
            message = "Текущий игрок: \(currentPlayer == .black ? "Черный" : "Белый")"
        }
        return message
    }
    
    func resetGame() {
        board = Array(repeating: nil, count: 64)
        board[3 * 8 + 3] = PieceOnBoard(player: .white)
        board[3 * 8 + 4] = PieceOnBoard(player: .black)
        board[4 * 8 + 3] = PieceOnBoard(player: .black)
        board[4 * 8 + 4] = PieceOnBoard(player: .white)
        
        blackCount = 2
        whiteCount = 2
        gameOver = false
        currentPlayer = .black
        updatePossibleMoves()
    }
    
    func getPiece(index: Int) -> PieceOnBoard? {
        return board[index]
    }
    
    func setPiece(index: Int, move: PieceOnBoard?) {
        board[index] = move
    }
    
    func placePiece(index: Int) {
        guard getPiece(index: index) == nil else { return }
        
        if possibleMoves.contains(index) {
            setPiece(index: index, move: PieceOnBoard(player: currentPlayer))
            flipPieces(position: index, player: currentPlayer)
            if currentPlayer == .black {
                blackCount += 1
            } else {
                whiteCount += 1
            }
            
            checkWin()
            togglePlayer()
            updatePossibleMoves()
            
            if gameMode == .playerVsAI && currentPlayer == .white {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.performAIMove()
                }
            }
        }
    }
    
    func performAIMove() {
        if let bestMove = findBestMoveForAI() {
            placePiece(index: bestMove)
        }
    }
    
    func findBestMoveForAI() -> Int? {
        var bestMove: Int? = nil
        var bestScore = -Float.infinity
        
        for move in possibleMoves {
            let score = evaluateMove(position: move, player: .white)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    func evaluateMove(position: Int, player: Player) -> Float {
        var score: Float = 0
        let ss: Float
        
        if isCorner(position) {
            ss = 0.8
        } else if isEdge(position) {
            ss = 0.4
        } else {
            ss = 0
        }
        
        score += ss
        
        for direction in directions where canCaptureInDirection(position: position, player: player, direction: direction) {
            var tempPos = position + direction
            while let move = getPiece(index: tempPos), move.player != player {
                score += isEdge(tempPos) ? 2 : 1
                tempPos += direction
            }
        }
        
        return score
    }
    
    func isCorner(_ index: Int) -> Bool {
        return [0, 7, 56, 63].contains(index)
    }
    
    func isEdge(_ index: Int) -> Bool {
        return (index % 8 == 0 || index % 8 == 7 || index < 8 || index >= 56) && !isCorner(index)
    }
    
    func findWinner() {
        if blackCount > whiteCount {
            winner = "black"
        } else if blackCount < whiteCount {
            winner = "white"
        } else {
            winner = "draw"
        }
    }
    
    func checkWin() {
        let allMoves = board.compactMap { $0 }
        if allMoves.count == 64 {
            findWinner()
            gameOver = true
            
        } else if allMoves.count < 64, possibleMoves.count == 0 {
            findWinner()
            gameOver = true
        }
    }
    
    func updatePossibleMoves() {
        possibleMoves.removeAll()
        for index in 0..<64 {
            if getPiece(index: index) == nil, isValidMove(position: index, player: currentPlayer) {
                possibleMoves.insert(index)
            }
        }
    }
    
    func isValidMove(position: Int, player: Player) -> Bool {
        for direction in directions {
            if canCaptureInDirection(position: position, player: player, direction: direction) {
                return true
            }
        }
        return false
    }
    
    func flipPieces(position: Int, player: Player) {
            for direction in directions {
                if canCaptureInDirection(position: position, player: player, direction: direction) {
                    var newPosition = position + direction
                    
                    while let move = getPiece(index: newPosition), move.player != player {
                        setPiece(index: newPosition, move: PieceOnBoard(player: player))
                        if currentPlayer == .black {
                            blackCount += 1
                            whiteCount -= 1
                        } else {
                            whiteCount += 1
                            blackCount -= 1
                        }
                        newPosition += direction
                    }
                }
            }
        }
    
    func canCaptureInDirection(position: Int, player: Player, direction: Int) -> Bool {
        var newPosition = position + direction
        var foundOpponent = false
        
        while newPosition >= 0, newPosition < 64, let move = getPiece(index: newPosition) {
            if move.player != player {
                foundOpponent = true
            } else if foundOpponent {
                return true
            } else {
                break
            }
            newPosition += direction
        }
        return false
    }
    
    func captureInDirection(position: Int, player: Player, direction: Int) {
        var newPosition = position + direction
        
        while newPosition >= 0, newPosition < 64, let move = getPiece(index: newPosition), move.player != player {
            setPiece(index: newPosition, move: PieceOnBoard(player: player))
            newPosition += direction
            
            if player == .black {
                blackCount += 1
                whiteCount -= 1
            } else {
                whiteCount += 1
                blackCount -= 1
            }
        }
    }
    
    func togglePlayer() {
        currentPlayer = (currentPlayer == .black) ? .white : .black
    }
    
}
