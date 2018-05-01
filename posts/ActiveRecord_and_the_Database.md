If you do things the Rails Way, including using the standard table names that come with the migrations generated using `rails generate migration`, you barely need to think about the underlying database. If you are interfacing with an existing database, or your models and the corresponding tables have different names, it can be a little more tricky. Luckily, ActiveRecord lets us specify the table, keys, and so on in these situations.

### A Quick Review of ActiveRecords's has_many and belongs_to

Let's look at a standard `has_many` and `belongs_to` relationship, using the Rails way:

```ruby
rails generate model investor
```

Gives the following model and migration:

```ruby
class Investor < ApplicationRecord
end
```

```ruby
class CreateInvestors < ActiveRecord::Migration[5.1]
  def change
    create_table :investors do |t|

      t.timestamps
    end
  end
end
```

And the corresponding database table:

```
________________________________
| id | created_at | updated_at |
--------------------------------
```

We now want a `house` that `belongs_to` an `investor`. Of course, an `investor` `has_many` `houses`. We can do this in one go:

```sh
rails generate model house investor:references
```

Which gives us:

```ruby
class House < ApplicationRecord
  belongs_to :investor
end
```

```ruby
class CreateHouses < ActiveRecord::Migration[5.1]
  def change
    create_table :houses do |t|
      t.references :investor, foreign_key: true

      t.timestamps
    end
  end
end
```

The corresponding table looks like this:

```
______________________________________________
| id | investor_id | created_at | updated_at |
----------------------------------------------
```

The Rails Way knows if we have a `belongs_to`, it will use the corresponding model's name and append `_id` to create the foreign key. 

There is one part we have to do by hand, however. If we drop down into `rails console` and run:

```ruby
Investor.new.houses
```

We get

```
NoMethodError: undefined method `houses' for #<Investor id: nil, created_at: nil, updated_at: nil>
```

That's because we need to add `has_many :houses` to the `investor` model:

```ruby
class Investor < ApplicationRecord
  has_many :houses
end
```

Now it works:

```ruby
i = Investor.new.save
i = Investor.first # load newly created investor

i.first.houses.create
#=> #<House id: 2, investor_id: 1, created_at: "2018-05-01 07:31:06", updated_at: "2018-05-01 07:31:06">
```

However, what if the model had been called something other than `investor`, or the database table had a different name? Let's build the able, using differently named models and tables, to see how to handle it.

### Creating the Table

Instead of generating the migration along with model, we will start with just the migration. The tables will be called `existing_investors` and `existing_houses`.

```sh
rails g migration create_existing_investor

bin/rails db:migrate
```

Now the model:

```sh
touch app/models/my_investor.ruby
```

```ruby
class MyInvestor < ApplicationRecord

end
```

Dropping into a `rails console` and running `MyInvestor.new` yields `ActiveRecord::StatementInvalid: Could not find table 'my_investors'`.

### Specifying the table

By default, Rails looks for a table which is the pluralized version of the model. We can specify another table name using `self.table_name`:

```ruby
class MyInvestor < ApplicationRecord
  self.table_name = "existing_investors"
end
```

The same thing can be applied for the initial `my_house` model and `existing_houses` migration:

```sh
rails g migration create_existing_house
```

```ruby
class CreateExistingHouse < ActiveRecord::Migration[5.1]
  def change
    create_table :existing_houses do |t|

      t.timestamps
    end
  end
end
```

```ruby
# app/models/my_house.ruby
class MyHouse < ApplicationRecord

end
```

Let's add the `has_many` relationship first. Instead of houses, I want to call them `investments`.

```ruby
class MyInvestor < ApplicationRecord
  self.table_name = "existing_investors"

  has_many :investments
end
```

`rails console` gives us:

```ruby
MyInvestor.first.investments
#=> NameError: uninitialized constant MyInvestor::Investment
```

Obviously, we don't even have an `investments` model. Try using `class_name`: 

```ruby
has_many :investments, class_name: 'MyHouse'
```

And we get a new error:

```ruby
MyHouse Load (0.3ms)  SELECT  "existing_houses".* FROM "existing_houses" WHERE "existing_houses"."my_investor_id" = ? LIMIT ?  [["my_investor_id", 1], ["LIMIT", 11]]

ActiveRecord::StatementInvalid: SQLite3::SQLException: no such column: existing_houses.my_investor_id: SELECT  "existing_houses".* FROM "existing_houses" WHERE "existing_houses"."my_investor_id" = ? LIMIT ?
```

**no such column: existing_houses.my_investor_id** is the important part. The logic goes like this:

`Investor` has_many `investments`. They are a model called `MyHouse`. So calling `investor.investments` looks to the `MyHouse` model, which in turn has a `class_name: 'existing_houses'` - whcih leads to a database query for `existing_houses` with an `id` prefixed by the model's table name, in this case `my_investor` - `my_investor_id`. 

We need to do *three* things:

1. Create a foreign key column on the `existing_houses` column. Since the table is called `existing_investors`, I want it to be called `existing_investor_id`.
2. Add `belongs_to` to `MyHouse`
3. add a `foreign_key` to the `has_many` function in `MyInvestor`

For the first step, we generate new migration:

```ruby
class AddInvestorKeyToMyHouse < ActiveRecord::Migration[5.1]
  def change
    change_table :existing_houses do |t|
      t.references :existing_investor, foreign_key: true
    end
  end
end
```

`t.references :existing_investor` creates a key of the same name with `_id` appended - so `existing_investor_id`.

For the second step, we can update `my_house.ruby`:


```ruby
class MyHouse < ApplicationRecord
  self.table_name = "existing_houses"

  belongs_to :buyer, class_name: "MyInvestor"
end
```

For the third, we update `MyHouse` as such:

```ruby
class MyHouse < ApplicationRecord
  self.table_name = "existing_houses"

  belongs_to :existing_investor, class_name: "MyInvestor"
end
```

Great! Now we can do:

```ruby
MyInvestor.first.investments.create!
#=> #<MyHouse id: 3, created_at: "2018-05-01 08:17:48", updated_at: "2018-05-01 08:17:48", existing_investor_id: 1>
```

Another nice thing Rails lets us to is customize the `belongs_to`, which can make the relationships between models more intuitive. Let's change `belongs_to :existing_investor` to `belongs_to :buyer`:

```ruby
class MyHouse < ApplicationRecord
  self.table_name = "existing_houses"

  belongs_to :buyer, class_name: "MyInvestor", foreign_key: "existing_investor_id"
end
```

And `MyInvestor.first.investments.create!` still works. Now we can type `MyHouse.last.buyer`, which is much more intuitive, and get:

```sh
#=> #<MyInvestor id: 1, created_at: "2018-05-01 07:39:21", updated_at: "2018-05-01 07:39:21">
```

RoR is not that trendy nowdays, but seeing the fantastic abstractions and power ActiveRecord deliverers out of the box, I still think RoR is the best way to build websites.
