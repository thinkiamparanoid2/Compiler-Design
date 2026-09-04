#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    string symbol_kind;
    string data_type;
    int array_size;
    vector<string> param_types;
    vector<string> param_names;

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->symbol_kind = "";
        this->data_type = "";
        this->array_size = 0;
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    string getname()
    {
        return name;
    }
    string gettype()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    string get_symbol_kind()
    {
        return symbol_kind;
    }
    void set_symbol_kind(string kind)
    {
        this->symbol_kind = kind;
    }
    string get_data_type()
    {
        return data_type;
    }
    void set_data_type(string dt)
    {
        this->data_type = dt;
    }
    int get_array_size()
    {
        return array_size;
    }
    void set_array_size(int size)
    {
        this->array_size = size;
    }
    vector<string> get_param_types()
    {
        return param_types;
    }
    vector<string> get_param_names()
    {
        return param_names;
    }
    void add_param(string ptype, string pname)
    {
        param_types.push_back(ptype);
        param_names.push_back(pname);
    }
    int get_param_count()
    {
        return param_types.size();
    }

    ~symbol_info()
    {
    }
};