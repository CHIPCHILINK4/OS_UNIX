#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <vector>
#include <filesystem>
#include <openssl/evp.h>
#include <sys/stat.h>

using namespace std;
namespace fsm = filesystem;

string doMD5(const fsm::path& filePath) {
    ifstream file(filePath, ios::binary);
    if (!file.is_open()) {
        return "";
    }

    EVP_MD_CTX* ctx = EVP_MD_CTX_new();
    if (!ctx) 
        return "";

    if (EVP_DigestInit_ex(ctx, EVP_md5(), nullptr) != 1) {
        EVP_MD_CTX_free(ctx);
        return "";
    }

    char buffer[8192];
    while (file.read(buffer, sizeof(buffer))) {
        EVP_DigestUpdate(ctx, buffer, file.gcount());
    }
    if (file.gcount() > 0) {
        EVP_DigestUpdate(ctx, buffer, file.gcount());
    }

    unsigned char hash[EVP_MAX_MD_SIZE];
    unsigned int hashLen = 0;
    EVP_DigestFinal_ex(ctx, hash, &hashLen);
    EVP_MD_CTX_free(ctx);

    string hexHash;
    for (unsigned int i = 0; i < hashLen; i++) {
        char hex[3];
        snprintf(hex, sizeof(hex), "%02x", hash[i]);
        hexHash += hex;
    }

    return hexHash;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        cerr << "ERR: вы не передали директорию, перезапустите и передайте первым аргументом путь до директории\n";
        return 1;
    }

    fsm::path targetDir = argv[1];

    if (!fsm::exists(targetDir) || !fsm::is_directory(targetDir)) {
        cerr << "ERR: '" << targetDir << "' не является каталогом\n";
        return 1;
    }

    map<string, vector<fsm::path>> hashMap;

    
    for (const auto& path : fsm::recursive_directory_iterator(targetDir)) {
        if (path.is_regular_file()) {
            string hash = doMD5(path.path());
            if (!hash.empty()) {
                hashMap[hash].push_back(path.path());
            }
        }
    }

    int linksCreated = 0;

    for (const auto& [hash, files] : hashMap) {
        if (files.size() <= 1) 
            continue;

        const fsm::path& orig = files[0];
        
        struct stat origStat;
        if (stat(orig.c_str(), &origStat) != 0)
            continue;

        for (size_t i = 1; i < files.size(); i++) {
            const fsm::path& duplicate = files[i];
            struct stat dupStat;
            if (stat(duplicate.c_str(), &dupStat) != 0)
                continue;

            if (origStat.st_dev != dupStat.st_dev) {
                cerr << "ERR Разные ФС: " << duplicate << endl;
                continue;
            }

            error_code ec;
            fsm::remove(duplicate, ec); 
            if (!ec) {
                fsm::create_hard_link(orig, duplicate, ec);
                if (!ec) {
                    linksCreated++;
                } else {
                    cerr << "ERR: создание ссылки " << duplicate << endl;
                }
            }
        }
    }

    cout << "Создано жёстких ссылок: " << linksCreated << endl;
    return 0;
}