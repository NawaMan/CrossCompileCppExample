#pragma once

#include <string>
#include <vector>
#include <utility>
#include <stdexcept>
#include <tuple>

namespace utils {

// Error handling with result type pattern (similar to std::expected but using std::pair)
using NumberResult = std::pair<int, std::string>; // (result, error_message)

// Parse a number with error handling
NumberResult parse_number(const std::string& input) {
    try {
        size_t pos = 0;
        int result = std::stoi(input, &pos);
        
        if (pos != input.size()) {
            return {0, "Not all characters were used in conversion"};
        }
        
        return {result, ""}; // Empty error message means success
    } catch (const std::invalid_argument&) {
        return {0, "Invalid argument"};
    } catch (const std::out_of_range&) {
        return {0, "Out of range"};
    }
}

// Check if a result has an error
bool has_error(const NumberResult& result) {
    return !result.second.empty();
}

// Get the error message from a result
const std::string& get_error(const NumberResult& result) {
    return result.second;
}

// Get the value from a result (throws if there's an error)
int get_value(const NumberResult& result) {
    if (has_error(result)) {
        throw std::runtime_error(result.second);
    }
    return result.first;
}

// A simple container class with modern C++ features
template <typename T>
class Container {
private:
    std::vector<T> data;
    
public:
    // Regular accessor methods
    const std::vector<T>& get_data() const {
        return data;
    }
    
    std::vector<T>& get_data() {
        return data;
    }
    
    void add(T value) {
        data.push_back(std::move(value));
    }
    
    // Using C++17 structured bindings compatible return
    std::tuple<bool, size_t> contains(const T& value) const {
        for (size_t i = 0; i < data.size(); ++i) {
            if (data[i] == value) {
                return {true, i};
            }
        }
        return {false, 0};
    }
};

// Compile-time vs runtime value determination
constexpr int get_compile_time_value() {
    return 42;
}

inline int get_runtime_value() {
    return 43;
}

} // namespace utils
