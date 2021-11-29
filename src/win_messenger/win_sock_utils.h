#pragma once
#include <string>
long connectAddr(const std::string& ip, const std::string& port);

void closeSock(long sock);
