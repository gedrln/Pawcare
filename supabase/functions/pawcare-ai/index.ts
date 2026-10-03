import 'jsr:@supabase/functions-js/edge-runtime.d.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods':
    'POST, OPTIONS',
};

type Pet = {
  name?: string;
  species?: string;
  breed?: string;
  age?: string;
  gender?: string;
};

type ConversationMessage = {
  role?: string;
  content?: string;
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
) {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type':
            'application/json',
      },
    },
  );
}

function extractOutputText(
  data: any,
): string {
  const output =
      Array.isArray(data?.output)
          ? data.output
          : [];

  const parts: string[] = [];

  for (const item of output) {
    if (!Array.isArray(item?.content)) {
      continue;
    }

    for (const content of item.content) {
      if (
        content?.type === 'output_text' &&
        typeof content.text === 'string'
      ) {
        parts.push(content.text);
      }
    }
  }

  return parts.join('\n').trim();
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(
      'ok',
      {
        headers: corsHeaders,
      },
    );
  }

  if (req.method !== 'POST') {
    return jsonResponse(
      {
        error:
            'Method not allowed.',
      },
      405,
    );
  }

  const openAiKey =
      Deno.env.get(
        'OPENAI_API_KEY',
      );

  if (!openAiKey) {
    return jsonResponse(
      {
        error:
            'OPENAI_API_KEY is not configured.',
      },
      500,
    );
  }

  let body: {
    message?: string;
    pet?: Pet;
    conversation?:
        ConversationMessage[];
  };

  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse(
      {
        error:
            'Invalid JSON body.',
      },
      400,
    );
  }

  const message =
      body.message?.trim();

  if (!message) {
    return jsonResponse(
      {
        error:
            'Message is required.',
      },
      400,
    );
  }

  const pet =
      body.pet ?? {};

 const conversation =
    Array.isArray(body.conversation)
        ? body.conversation
            .filter(
              (item) =>
                  (
                    item.role === 'user' ||
                    item.role === 'assistant'
                  ) &&
                  typeof item.content === 'string' &&
                  item.content.trim().length > 0,
            )
            .slice(-12)
        : [];

  const petContext = [
    `Name: ${pet.name ?? 'Unknown'}`,
    `Species: ${pet.species ?? 'Unknown'}`,
    `Breed: ${pet.breed ?? 'Unknown'}`,
    `Age: ${pet.age ?? 'Unknown'}`,
    `Gender: ${pet.gender ?? 'Unknown'}`,
  ].join('\n');

  const input = [
    ...conversation.map(
      (item) => ({
        role: item.role,
        content: item.content,
      }),
    ),

    {
      role: 'user',
      content: message,
    },
  ];

  try {
    const response =
        await fetch(
      'https://api.openai.com/v1/responses',
      {
        method: 'POST',

        headers: {
          'Content-Type':
              'application/json',

          'Authorization':
              `Bearer ${openAiKey}`,
        },

        body: JSON.stringify({
          model: 'gpt-5-mini',

          instructions: `
You are Pawcare AI, a friendly pet-care assistant inside the Pawcare mobile application.

The current pet is:

${petContext}

Give clear, friendly, practical, and easy-to-understand general pet-care information.

Use the pet's information when relevant.

Do not invent information about the pet.

Do not claim to diagnose diseases.

Do not replace a veterinarian.

If the user describes severe, sudden, or potentially dangerous symptoms, recommend contacting a licensed veterinarian or emergency veterinary service promptly.

Keep normal answers concise enough for a small mobile chat window.

If the user asks something unrelated to pet care, politely explain that you are Pawcare AI and are primarily designed to help with pet-care questions.
`,

          input,

          max_output_tokens: 500,
        }),
      },
    );

    if (!response.ok) {
      const errorText =
          await response.text();

      console.error(
        'OpenAI error:',
        errorText,
      );

      return jsonResponse(
        {
          error:
              'The AI service could not complete the request.',
        },
        502,
      );
    }

    const data =
        await response.json();

    const reply =
        extractOutputText(data);

    if (!reply) {
      return jsonResponse(
        {
          error:
              'The AI returned an empty response.',
        },
        502,
      );
    }

    return jsonResponse({
      reply,
    });
  } catch (error) {
    console.error(
      'AI request failed:',
      error,
    );

    return jsonResponse(
      {
        error:
            'Unable to connect to the AI service.',
      },
      500,
    );
  }
});