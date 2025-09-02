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

import Testing

@testable import SynchronousLock

@Test
func withLock_providesInitialValue() {
	let lock = Lock(42)

	lock.withLock { value in
		#expect(value == 42)
	}
}

@Test
func withLock_allowsValueMutation() {
	let lock = Lock(10)

	lock.withLock { value in
		value += 5
	}

	let result = lock.withLock(\.self)
	#expect(result == 15)
}

@Test
func withLock_returnsClosureResult() {
	let lock = Lock(7)

	let result = lock.withLock { value in
		value * 3
	}

	#expect(result == 21)
}

@Test
func withLock_propagatesErrors() {
	let lock = Lock(0)

	enum TestError: Error {
		case testFailure
	}

	#expect(throws: TestError.testFailure) {
		_ = try lock.withLock { _ -> Int in
			throw TestError.testFailure
		}
	}
}

@Test
func withLock_remainsUsableAfterError() {
	let lock = Lock(0)

	enum TestError: Error {
		case testFailure
	}

	// Cause an error
	#expect(throws: TestError.testFailure) {
		_ = try lock.withLock { _ -> Int in
			throw TestError.testFailure
		}
	}

	// Verify lock still works
	let result = lock.withLock { value in
		value = 100
		return value
	}
	#expect(result == 100)
}

@Test
func withLock_worksWithStringType() {
	let lock = Lock("hello")

	let result = lock.withLock { value in
		value += " world"
		return value.uppercased()
	}

	#expect(result == "HELLO WORLD")
}

@Test
func withLock_worksWithArrayType() {
	let lock = Lock([1, 2, 3])

	lock.withLock { value in
		value.append(4)
	}

	#expect(lock.withLock(\.self) == [1, 2, 3, 4])
}

@Test
func withLock_worksWithDictionaryType() {
	let lock = Lock(["key": "value"])

	lock.withLock { value in
		value["new"] = "data"
	}

	#expect(lock.withLock(\.self).keys.count == 2)
}

@Test
func withLock_handlesComplexDataStructures() {
	struct Counter {
		var value: Int = 0

		mutating func increment() {
			value += 1
		}
	}

	let lock = Lock(Counter())

	lock.withLock { counter in
		counter.increment()
	}

	#expect(lock.withLock(\.self).value == 1)
}

@Test
func withLock_mutatesAndReturns() {
	let lock = Lock(5)

	let returnedValue = lock.withLock { value in
		value *= 2
		return value + 10
	}

	#expect(returnedValue == 20)
	#expect(lock.withLock(\.self) == 10)
}

@Test
func withLock_providesThreadSafety() async {
	let lock = Lock(0)
	let iterations = 1_000
	let taskCount = 10

	await withTaskGroup(of: Void.self) { group in
		for _ in 0..<taskCount {
			group.addTask {
				for _ in 0..<iterations {
					lock.withLock { value in
						value += 1
					}
				}
			}
		}
	}

	#expect(lock.withLock(\.self) == taskCount * iterations)
}

@Test
func withLock_worksConcurrentlyAcrossTasks() async {
	let lock = Lock([String]())

	await withTaskGroup(of: String.self) { group in
		for i in 0..<5 {
			group.addTask {
				let identifier = "task-\(i)"
				lock.withLock { array in
					array.append(identifier)
				}
				return identifier
			}
		}

		await group.waitForAll()
	}

	#expect(lock.withLock(\.self).count == 5)
}
