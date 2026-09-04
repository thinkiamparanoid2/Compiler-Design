#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        int sum = 0;
        for (int i = 0; i < name.length(); i++)
        {
            sum = sum + name[i];
        }
        return sum % bucket_count;
    }

public:
    scope_table()
    {
        bucket_count = 0;
        unique_id = 0;
        parent_scope = NULL;
    }

    scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
    }

    scope_table *get_parent_scope()
    {
        return parent_scope;
    }

    int get_unique_id()
    {
        return unique_id;
    }

    symbol_info *lookup_in_scope(symbol_info *symbol)
    {
        int index = hash_function(symbol->get_name());
        for (list<symbol_info *>::iterator it = table[index].begin(); it != table[index].end(); it++)
        {
            if ((*it)->get_name() == symbol->get_name())
            {
                return *it;
            }
        }
        return NULL;
    }

    bool insert_in_scope(symbol_info *symbol)
    {
        if (lookup_in_scope(symbol) != NULL)
        {
            return false;
        }
        int index = hash_function(symbol->get_name());
        table[index].push_back(symbol);
        return true;
    }

    bool delete_from_scope(symbol_info *symbol)
    {
        int index = hash_function(symbol->get_name());
        for (list<symbol_info *>::iterator it = table[index].begin(); it != table[index].end(); it++)
        {
            if ((*it)->get_name() == symbol->get_name())
            {
                table[index].erase(it);
                return true;
            }
        }
        return false;
    }

    void print_scope_table(ofstream &outlog)
    {
        outlog << "ScopeTable # " << to_string(unique_id) << endl;
        for (int i = 0; i < bucket_count; i++)
        {
            if (table[i].size() > 0)
            {
                outlog << i << " --> " << endl;
                for (list<symbol_info *>::iterator it = table[i].begin(); it != table[i].end(); it++)
                {
                    outlog << "< " << (*it)->get_name() << " : " << (*it)->get_type() << " >" << endl;
                    outlog << (*it)->get_symbol_kind() << endl;
                    if ((*it)->get_symbol_kind() == "Function Definition")
                    {
                        outlog << "Return Type: " << (*it)->get_data_type() << endl;
                        outlog << "Number of Parameters: " << (*it)->get_param_count() << endl;
                        outlog << "Parameter Details: ";
                        vector<string> ptypes = (*it)->get_param_types();
                        vector<string> pnames = (*it)->get_param_names();
                        for (int j = 0; j < ptypes.size(); j++)
                        {
                            if (j > 0)
                                outlog << ", ";
                            outlog << ptypes[j] << " " << pnames[j];
                        }
                        outlog << endl;
                    }
                    else if ((*it)->get_symbol_kind() == "Array")
                    {
                        outlog << "Type: " << (*it)->get_data_type() << endl;
                        outlog << "Size: " << (*it)->get_array_size() << endl << endl;
                    }
                    else
                    {
                        outlog << "Type: " << (*it)->get_data_type() << endl << endl;
                    }
                }
            }
        }
        outlog << endl;
    }

    ~scope_table()
    {
        for (int i = 0; i < bucket_count; i++)
        {
            for (list<symbol_info *>::iterator it = table[i].begin(); it != table[i].end(); it++)
            {
                delete *it;
            }
        }
    }
};