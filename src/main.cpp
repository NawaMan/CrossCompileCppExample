#include <iostream>
#include <string>
#include <vector>
#include <optional>
#include <memory>
#include <algorithm>

// A simple function using modern C++ features
void print_info(const std::vector<std::string>& args) {
    std::cout << "Running with " << args.size() << " arguments\n";
    
    // Using C++11/14 features: range-based for loop
    for (size_t i = 0; i < args.size(); ++i) {
        std::cout << "Argument " << i << ": " << args[i] << "\n";
    }
}

// A simple class with modern C++ features
class ModernCppDemo {
private:
    std::vector<std::string> data;
    
public:
    // Using C++11 constructor delegation
    ModernCppDemo() : ModernCppDemo({}) {}
    
    // Using C++11 initializer lists
    ModernCppDemo(std::initializer_list<std::string> init) : data(init) {}
    
    // Using C++14 auto return type deduction
    auto size() const {
        return data.size();
    }
    
    // Using C++14 generic lambdas
    void transform_all(const std::string& prefix) {
        std::transform(data.begin(), data.end(), data.begin(),
            [&prefix](const auto& item) {
                return prefix + item;
            });
    }
    
    // Using C++17 structured bindings compatible syntax
    std::pair<size_t, bool> add_if_not_exists(const std::string& item) {
        auto it = std::find(data.begin(), data.end(), item);
        if (it == data.end()) {
            data.push_back(item);
            return {data.size() - 1, true};
        }
        return {std::distance(data.begin(), it), false};
    }
    
    // Using C++17 optional
    std::optional<std::string> get_at(size_t index) const {
        if (index < data.size()) {
            return data[index];
        }
        return std::nullopt;
    }
    
    // Print all items
    void print() const {
        for (const auto& item : data) {
            std::cout << item << "\n";
        }
    }
};

int main(int argc, char* argv[]) {
    std::cout << "Hello from Modern C++ Cross-Compilation Example!\n";
    
    // Convert command line arguments to strings
    std::vector<std::string> args;
    for (int i = 0; i < argc; ++i) {
        args.push_back(argv[i]);
    }
    
    // Print command line arguments
    print_info(args);
    
    // Demonstrate modern C++ features
    ModernCppDemo demo{"apple", "banana", "cherry"};
    
    std::cout << "\nOriginal items:\n";
    demo.print();
    
    // Add a new item if it doesn't exist
    auto [index, added] = demo.add_if_not_exists("date");
    std::cout << "\nAdded 'date' at index " << index << ", newly added: " << (added ? "yes" : "no") << "\n";
    
    // Transform all items
    demo.transform_all("fruit: ");
    std::cout << "\nAfter transformation:\n";
    demo.print();
    
    // Use optional to safely access an item
    auto item = demo.get_at(1);
    if (item) {
        std::cout << "\nItem at index 1: " << *item << "\n";
    }
    
    // Try to access an out-of-bounds item
    auto nonexistent = demo.get_at(10);
    std::cout << "Item at index 10 exists: " << (nonexistent.has_value() ? "yes" : "no") << "\n";
    
    return 0;
}
