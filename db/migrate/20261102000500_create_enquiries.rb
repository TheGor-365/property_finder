class CreateEnquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :enquiries do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name, limit: 120, null: false
      t.string :email, limit: 254, null: false
      t.text :message, null: false
      t.string :status, limit: 20, null: false, default: "new"
      t.timestamps
    end
    add_index :enquiries, [:property_id, :created_at]
  end
end
