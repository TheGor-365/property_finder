namespace :pf do
  namespace :demo do
    desc "Add original educational Property Finder demo articles (test/development only)"
    task articles: :environment do
      unless Rails.env.development? || Rails.env.test?
        abort "Refusing to seed demonstration articles outside development/test."
      end

      articles = [
        {
          slug: "viewing-checklist",
          title: "A better property viewing starts before the front door",
          summary: "A practical, room-by-room framework for comparing spaces without relying on first impressions.",
          body: <<~ARTICLE
            A viewing is more useful when you know what you want to learn. Before you arrive, write down the essentials: the number of usable rooms, the commute you can tolerate, whether you need accessible entry, and the storage you actually use. Keeping a consistent checklist makes different homes easier to compare.

            Start with the everyday layout. Stand in the kitchen and imagine preparing a meal while somebody else moves through the room. Check whether doors can open freely, whether natural light reaches your preferred workspace, and whether bedrooms have usable furniture walls. Room dimensions can be more informative than a headline square-footage figure.

            Check fixtures without making assumptions. Ask which appliances and fittings are included, whether heating and cooling are operational, and what maintenance records are available. Notice ventilation, visible signs of moisture, window seals, water pressure and noise from surrounding spaces. If a technical inspection is needed, ask a qualified professional rather than trying to diagnose a structure during a viewing.

            Afterwards, record three things: what worked, what needs confirmation, and what would be a deal-breaker. Take only photographs for which you have permission. A clear written comparison will help you separate an attractive presentation from a property that actually fits your needs.
          ARTICLE
        },
        {
          slug: "rental-budget",
          title: "The monthly rent is only one line of the budget",
          summary: "Build a realistic comparison of rent, deposits, utilities and move-in costs.",
          body: <<~ARTICLE
            A rental listing usually begins with a monthly price. That figure is useful, but it is not the full cost of living in a property. Build a simple budget with separate lines for rent, utilities, internet, parking, building fees and any recurring services that matter to you.

            Then consider the move-in amount. Depending on the agreement and local rules, you may need an initial rental payment, a refundable security deposit, agency charges or setup costs. Never assume a fee applies—or does not apply—without checking the specific agreement. Request an itemised explanation before transferring money.

            Ask how running costs are estimated. Actual utility consumption depends on occupancy, climate, insulation and tariffs, so a neighbour's bill or an online average is not a guarantee. When possible, compare the same categories across every property rather than choosing based on rent alone.

            Keep documents, payment instructions and property details in one place. Verify the identity and authority of the person offering the lease, visit or independently inspect the home where appropriate, and review the signed terms before paying. A little structure protects both your time and your budget.
          ARTICLE
        },
        {
          slug: "good-enquiry",
          title: "How to send a property enquiry that gets useful answers",
          summary: "Ask concise, specific questions and keep the first message focused on the next step.",
          body: <<~ARTICLE
            A useful enquiry gives the listing agent enough context to answer without turning your first message into a long negotiation. Introduce yourself briefly, name the listing and explain whether you are asking about a viewing, availability or a particular feature.

            Choose two or three questions that matter now. You might ask whether the advertised price includes parking, whether pets are considered, or which documents are available for review. Leave detailed negotiation until you understand the basics and have verified the listing.

            Share only the contact information necessary for a reply. Do not include passport numbers, bank information, access codes or copies of sensitive documents in an introductory enquiry. A professional agent can explain later what formal checks are required and through which secure channel.

            Keep a record of the date you contacted the agent and any answer you received. If the listing is no longer available, ask whether there are comparable alternatives. A short, respectful message makes the next step clear while allowing you to compare responses from different listings.
          ARTICLE
        },
        {
          slug: "buying-comparison",
          title: "Compare homes with a decision matrix, not memory",
          summary: "A simple weighted score helps separate must-haves from features that just look appealing.",
          body: <<~ARTICLE
            When several properties seem appealing, the small details become difficult to remember. A comparison matrix keeps the decision transparent. Begin with criteria you can observe or verify: total price, location, layout, storage, accessibility, condition and expected running costs.

            Mark each criterion as essential, desirable or optional. Essentials should act as a filter; there is little value in assigning a high score to a property that cannot meet a non-negotiable requirement. For the remaining properties, use a consistent rating scale and write down evidence for each score.

            Avoid treating a single total score as a fact. The matrix is a thinking aid, not a valuation or a substitute for inspection, legal review or professional advice. Use the score to identify where you need more information, such as the condition of shared infrastructure or the terms of a planned renovation.

            Review the same questions after every viewing. Ask what you learned that changed your priorities. You may discover that travel time matters more than an extra room, or that maintenance requirements make a lower headline price less attractive.
          ARTICLE
        },
        {
          slug: "listing-photography",
          title: "What good listing photography should actually show",
          summary: "A complete gallery builds trust by showing how rooms connect, not just their best angles.",
          body: <<~ARTICLE
            Photos help visitors decide which listings deserve attention. They should explain the space rather than hide its limitations. A useful set begins with a clear overview of the main living area and then shows the kitchen, bedrooms, bathrooms, circulation space and any outdoor areas.

            Consistency matters more than dramatic filters. Aim for level horizons, balanced lighting and an honest depiction of scale. Very wide lenses can make rooms appear larger; if you use one, complement it with a view that helps readers understand actual proportions. Keep furniture and finishes accurate.

            Add context where appropriate. A floor plan, dimensions and captions can clarify how rooms connect. Photos should not imply that an excluded furnishing, neighbouring view or facility belongs to the property. Never use imagery from another address as though it represents the advertised home.

            For a demo portfolio, illustrative artwork or generated interiors may be useful to demonstrate layout and visual design, but they must be labelled as illustrations and not presented as evidence of an actual property. Permission and truthful labelling are part of professional content design.
          ARTICLE
        },
        {
          slug: "demo-experience",
          title: "Behind the demonstration: from listing to agent inbox",
          summary: "How the sample Property Finder experience works—and which parts are intentionally fictional.",
          body: <<~ARTICLE
            Property Finder is presented here as a software demonstration. The sample listings marked DEMO use fictional addresses, sample prices and test accounts. They are not real offers, and visitors should not attempt to book or pay for them.

            The core journey illustrates a real product pattern. A visitor can browse available listings, open a detail page and submit an enquiry through a validated form. The application saves that enquiry in its database, and the agent can review messages related to their own listings.

            Inside the agent workspace, enquiry statuses help organise follow-up work. A message starts as New and can be marked Contacted or Closed. Those labels represent workflow state only; they are not evidence of actual contact, contracts, bookings or sales.

            A production property marketplace would require additional controls, including verified inventory, media rights, stronger anti-abuse protections, reliable delivery infrastructure and operational support. Keeping these distinctions explicit makes the demonstration useful without creating false expectations.
          ARTICLE
        }
      ]

      created = 0
      skipped = 0

      articles.each do |article|
        reference = "pf-demo-#{article.fetch(:slug)}"
        if Post.exists?(url: reference)
          skipped += 1
          next
        end

        Post.create!(
          url: reference,
          title: article.fetch(:title),
          summary: article.fetch(:summary),
          body: article.fetch(:body).strip,
          active: true
        )
        created += 1
      end

      puts "PF_DEMO_ARTICLES_CREATED=#{created}"
      puts "PF_DEMO_ARTICLES_EXISTING=#{skipped}"
      puts "PF_DEMO_ARTICLES_TOTAL=#{articles.size}"
      puts "PF_DEMO_ARTICLES_SCOPE=#{Rails.env}"
    end
  end
end
