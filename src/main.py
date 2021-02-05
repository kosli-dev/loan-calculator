#!/usr/bin/env python


def load_unsafe_yaml():
    import yaml
    # Uncomment this line to create a security issue - unsafe yaml load
    yaml.load("yaml_str")

def main():
    print("Loan calculator")


if __name__ == '__main__':
    main()
