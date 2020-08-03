//
//  main.swift
//  CommandLine
//
//  Created by Joshua Adams on 8/2/20.
//  Copyright © 2020 Joshua Adams. All rights reserved.
//

import Foundation
import SwiftSyntax
import TSCBasic

try withTemporaryFile(dir: nil, deleteOnClose: true) { temp in
  temp.fileHandle.write("5.3_8 0xDEAD.BEEFp2 0b10101 0o3434 4_2 0xDEADBEEF".data(using: .utf8)!)
  let url = URL(fileURLWithPath: temp.path.pathString)
  let sourceFile = try SyntaxParser.parse(url)
  _ = VisitNumericLiterals().visit(sourceFile)
}

class VisitNumericLiterals: SyntaxRewriter {
  override func visit(_ token: TokenSyntax) -> Syntax {
    if case .integerLiteral(let text) = token.tokenKind {
      let digits = SyntaxFactory.makeIntegerLiteral(text)
      let intLiteralExpr = SyntaxFactory.makeIntegerLiteralExpr(digits: digits)
      print("text: \(text) integerValue: \(intLiteralExpr.integerValue)")
    } else if case .floatingLiteral(let text) = token.tokenKind {
      let digits = SyntaxFactory.makeFloatingLiteral(text)
      let floatLiteralExpr = SyntaxFactory.makeFloatLiteralExpr(floatingDigits: digits)
      print("text: \(text) floatingValue: \(floatLiteralExpr.floatingValue)")
    }
    return Syntax(token)
  }
}

public extension FloatLiteralExprSyntax {
  var floatingValue: Double {
    let floatingDigitsWithoutUnderscores = floatingDigits.text.filter {
      $0 != "_"
    }
    return Double(floatingDigitsWithoutUnderscores)!
  }
}

public extension IntegerLiteralExprSyntax {
  var integerValue: Int {
    let text = self.digits.text

    let type: IntegerType
    if text.count >= 2 {
      type = IntegerType(prefix: String(text.prefix(2)))
    } else {
      type = .decimal
    }

    let textWithoutPrefix: String
    switch type {
    case .binary, .octal, .hexadecimal:
      let prefixLength = 2
      let index = text.index(text.startIndex, offsetBy: prefixLength)
      textWithoutPrefix = String(text.suffix(from: index))
    case .decimal:
      textWithoutPrefix = text
    }

    let textWithoutPrefixOrUnderscores = textWithoutPrefix.filter {
      $0 != "_"
    }

    return Int(textWithoutPrefixOrUnderscores, radix: type.radix())!
  }

  enum IntegerType {
    case binary
    case octal
    case decimal
    case hexadecimal

    init(prefix: String) {
      switch prefix {
      case "0b":
        self = .binary
      case "0o":
        self = .octal
      case "0x":
        self = .hexadecimal
      default:
        self = .decimal
      }
    }

    func radix() -> Int {
      switch self {
      case .binary:
        return 2
      case .octal:
        return 8
      case .decimal:
        return 10
      case .hexadecimal:
        return 16
      }
    }
  }
}

