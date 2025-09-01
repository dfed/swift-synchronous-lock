// Distributed under the MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if canImport(Foundation)
	import Foundation
#endif

#if canImport(os)
	import os
#endif

public final class Lock<Value>: Sendable {
	// MARK: Initialization

	public init(_ initialValue: consuming sending Value) {
		#if canImport(os) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
			if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, visionOS 1.0, *) {
				underlyingLock = OSAllocatedUnfairLockWrapper(initialValue)
			} else {
				#if canImport(Foundation)
					underlyingLock = NSLockWrapper(initialValue)
				#else
					#error("No suitable lock implementation available")
				#endif
			}
		#elseif canImport(Foundation)
			underlyingLock = NSLockWrapper(initialValue)
		#else
			#error("No suitable lock implementation available")
		#endif
	}

	// MARK: Public

	public func withLock<Result, E: Error>(_ body: (inout Value) throws(E) -> Result) throws(E) -> Result {
		try underlyingLock.withLock(body)
	}

	// MARK: Private

	private let underlyingLock: any LockProtocol<Value>
}

// MARK: - Lock Protocol

private protocol LockProtocol<Value>: Sendable {
	associatedtype Value

	func withLock<Result, E: Error>(_ body: (inout Value) throws(E) -> Result) throws(E) -> Result
}

// MARK: - OSAllocatedUnfairLock Wrapper

#if canImport(os) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS))
	@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, visionOS 1.0, *)
	private final class OSAllocatedUnfairLockWrapper<Value>: LockProtocol, Sendable {
		init(_ initialValue: consuming sending Value) {
			lock = OSAllocatedUnfairLock(uncheckedState: initialValue)
		}

		func withLock<Result, E: Error>(_ body: (inout Value) throws(E) -> Result) throws(E) -> Result {
			do {
				return try lock.withLockUnchecked { value in
					try body(&value)
				}
			} catch {
				throw error as! E
			}
		}

		private let lock: OSAllocatedUnfairLock<Value>
	}
#endif

// MARK: - NSLock Wrapper

#if canImport(Foundation)
	private final class NSLockWrapper<Value>: LockProtocol, @unchecked Sendable {
		init(_ initialValue: consuming sending Value) {
			value = initialValue
		}

		func withLock<Result, E: Error>(_ body: (inout Value) throws(E) -> Result) throws(E) -> Result {
			lock.lock()
			defer { lock.unlock() }
			return try body(&value)
		}

		private let lock = NSLock()
		private var value: Value
	}
#endif
