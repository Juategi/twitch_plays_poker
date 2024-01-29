def saveListToFile(file_path, string_list):
    with open(file_path, 'w') as file:
        for string in string_list:
            file.write(string + '\n')

def retrieveListFromFile(file_path):
    string_list = []
    with open(file_path, 'r') as file:
        for line in file:
            string_list.append(line.strip())
    return string_list

def saveIntToFile(file_path, number):
    with open(file_path, 'w') as file:
        file.write(str(number))

def retrieveIntFromFile(file_path):
    with open(file_path, 'r') as file:
        number = int(file.read())
    return number

