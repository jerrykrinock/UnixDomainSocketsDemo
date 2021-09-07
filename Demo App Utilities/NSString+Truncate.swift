extension String {
    /**  Truncates a string to a given limit of characters, max,
     by replacing words or characters about 2/3 of the way through with
     an ellipsis if the receiver exceeds the limit
    
     If the receiver does not exceed the limit, returns self
     only whole words.  This will generally result in a string which
     has a length somewhat less than the given limit.  If you pass YES
     and the given limit cannot be achieved by removing words, which is
     generally because it contains a word which is longer than the limit
     all by itself, characters are truncated instead.
     - Parameters:
     - limit:  The maximum number of characters allowed
     - wholeWords:  YES to try and truncate the string by removing
     - returns: truncated string
     */
    func stringByTruncatingMiddle(
        toLength limit: Int,
        wholeWords: Bool
    ) -> String! {
        let length = count
        var answer: String? = nil
        if length <= limit {
            answer = self as String
        } else if limit > 0 {
            let ellipsisAllowance = 3
            let limitNotIncludingEllipsis = limit - ellipsisAllowance
            var done = false
            if wholeWords {
                var words = components(separatedBy: " ")
                // Keep removing the word which is at approximately 2/3 of the way
                // through the string until we're under the limit
                var newLength = length
                while words.count > 1 {
                    let targetIndex = words.count * 2 / 3
                    let removedWord = words[targetIndex]
                    words.remove(at: targetIndex)
                    newLength -= removedWord.count + 1
                    // In the above, the +1 is to remove the space between the
                    // removed word and the next word
                    if newLength <= limitNotIncludingEllipsis {
                        done = true
                        let priorIndex = targetIndex - 1
                        let priorWord = words[priorIndex]
                        var ending: String?
                        let ellipsisWillBeAtEnd = words.count >= targetIndex
                        if !ellipsisWillBeAtEnd {
                            // There will be words after the ellipsis
                            ending = " \(words[targetIndex])"
                        }
                        let truncation = "\(priorWord) … \(ending ?? "")"
                        words[priorIndex] = truncation
                        if !ellipsisWillBeAtEnd {
                            words.remove(at: targetIndex)
                        }
                        answer = words.joined(separator: " ")
                        break
                    }
                }
            }
            
            if !done {
                let endLength =  limitNotIncludingEllipsis / 3
                let beginLength = limit - endLength - 1 // reserve 1 for the ellipsis
                let endLocation = String.Index(utf16Offset: (length - endLength), in: self)
                answer = self.prefix(beginLength) + "…" + self.suffix(from: endLocation)
            }
        } else {
            answer = ""
        }

        return answer
    }

    func stringByTruncatingEnd(
        toLength limit: Int,
        wholeWords: Bool
    ) -> String! {
        let length = count
        var answer: String? = nil
        if length <= limit {
            answer = self as String
        } else if limit > 0 {
            let ellipsisAllowance = 1
            let limitNotIncludingEllipsis = limit - ellipsisAllowance
            var done = false
            if wholeWords {
                var words = components(separatedBy: " ")
                // Keep removing the last word until we're under the limit
                var newLength = length
                while words.count > 1 {
                    let removedWord = words.last
                    words.removeLast()
                    newLength -= (removedWord?.count ?? 0) + 1
                    // In the above, the +1 is to remove the space between the
                    // removed word and the prior word
                    if newLength <= limitNotIncludingEllipsis {
                        done = true
                        let lastWord = words.last
                        let truncation = lastWord ?? "" + "…"
                        words[words.count - 1] = truncation
                        answer = words.joined(separator: " ")
                        break
                    }
                }
            }

            if !done {
                let length = limit-1 // reserve 1 for the ellipsis
                answer = self.prefix(length) + "…"
            }
        } else {
            answer = ""
        }

        return answer
    }
}
