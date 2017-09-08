require 'qif'

class QifCreator
  def initialize(transactions)
    @transactions = transactions
  end

  def map_category(cat)
    category_map = {
      'eating_out' => 'Dining-Restaurants',
      'groceries' => 'Groceries',
      'entertainment' => 'Entertainment',
      'shopping' => 'Clothing-Shoes',
      'transport' => 'Travel',
      'cash' => 'ATM-Cash Withdrawals'
    }
    if category_map.include?(cat)
      category_map[cat]
    else
      nil
    end
  end

  def create(path = nil, settled_only: false)
    path ||= 'exports'
    path.chomp!('/')

    file = File.open("#{path}/#{rand(999)}_#{Time.now.to_i}.qif", "w")
    Qif::Writer.open(file.path, type = 'Bank', format = 'dd/mm/yyyy') do |qif|
      total_count = @transactions.size
      @transactions.each_with_index do |transaction, index|

        transaction.created = DateTime.parse(transaction.created)

        print "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] Exporting [#{transaction.created.to_s}] #{transaction.id}... "

        if transaction.amount.to_i == 0
          puts 'skipped: amount is 0'.light_blue
          next
        end

        if transaction.decline_reason
          puts 'skipped: declined transaction'.red
          next
        end

        if transaction.settled.empty? && settled_only
          puts 'skipped: transaction is not settled'.light_blue
          next
        end

        if ! transaction.notes.empty?
          memo = "#{transaction.notes} - #{transaction.description}"
        else
          memo = transaction.description
        end

        memo.strip!

        qif << Qif::Transaction.new(
          date: transaction.created,
          amount: transaction.amount.to_f/100,
          status: transaction.settled.to_s.empty? ? nil : 'c',
          memo: memo,
          payee: (transaction.merchant ? transaction.merchant.name : transaction.description) || (transaction.is_load ? 'Topup' : 'Unknown'),
          category: ( map_category(transaction.category) unless transaction.is_load )
        )

        puts 'exported'.green
      end
    end

    puts ''
    puts "Exported to: #{file.path}"
  end
end
