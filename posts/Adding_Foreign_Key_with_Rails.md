Rails makes it easy to add keys and indexes using migrations. Here is a quick example.

Say we have two such models:

```ruby
class File < ActiveRecord
  belongs_to :folder
end

class Folder < ActiveRecord
  has_many :files
end
```

And the database is a from a legacy application, and has no keys. We can update it to have a foreign key and index easily.

```bash
rails generate migration add_key_and_index
```

To add some more complexity, `File` has a `folder_id`, which should be related to the `Folder.id`.

The migration looks like this. 

```ruby
class AddKeyToFiles < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :files, :folders, column: :folder_id, index: true
  end
end
```

We can check if it worked by running `show indexes from files` in MySQL.

To compare, before the migration we have:

```bash
+---------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| Table         | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
+---------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| storage_files |          0 | PRIMARY  |            1 | id          | A         |          84 |     NULL | NULL   |      | BTREE      |         |               |
+---------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
```

And after:

```bash
+---------------+------------+---------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| Table         | Non_unique | Key_name            | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
+---------------+------------+---------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| storage_files |          0 | PRIMARY             |            1 | id          | A         |           0 |     NULL | NULL   |      | BTREE      |         |               |
| storage_files |          1 | fk_rails_549951770a |            1 | folder_id   | A         |           0 |     NULL | NULL   | YES  | BTREE      |         |               |
+---------------+------------+---------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
```

Pretty difficult to read since the table wraps on most monitors, but you can see the key was added.
