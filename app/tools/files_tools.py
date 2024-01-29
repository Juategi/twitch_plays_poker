def save_list_to_file(file_path, string_list):
    with open(file_path, 'w') as file:
        for string in string_list:
            file.write(string + '\n')

def retrieve_list_from_file(file_path):
    string_list = []
    with open(file_path, 'r') as file:
        for line in file:
            string_list.append(line.strip())
    return string_list
